// lib/features/invoices/presentation/widgets/invoice_payment_form_widget.dart
import 'package:flutter/material.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../../app/core/utils/number_input_formatter.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/shared/widgets/bank_account_selector.dart';
import '../controllers/invoice_detail_controller.dart';
import '../../domain/entities/invoice.dart';
import '../../../bank_accounts/domain/entities/bank_account.dart';

/// Tipo de pago seleccionado en el formulario
enum _PaymentType { cash, bankAccount }

/// Widget de formulario de pago para el detalle de factura
/// Permite pagar en efectivo (sin cuenta bancaria) o seleccionar una cuenta registrada
class InvoicePaymentFormWidget extends StatefulWidget {
  final InvoiceDetailController controller;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  const InvoicePaymentFormWidget({
    super.key,
    required this.controller,
    required this.onCancel,
    required this.onSubmit,
  });

  @override
  State<InvoicePaymentFormWidget> createState() => _InvoicePaymentFormWidgetState();
}

class _InvoicePaymentFormWidgetState extends State<InvoicePaymentFormWidget> {
  _PaymentType _paymentType = _PaymentType.cash;
  BankAccount? _selectedAccount;

  @override
  void initState() {
    super.initState();
    // Default: efectivo sin cuenta bancaria
    widget.controller.setPaymentMethod(PaymentMethod.cash);
    widget.controller.setBankAccountId(null);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);

    // Tamaños responsivos compactos
    final cardPadding = isMobile ? 12.0 : (isTablet ? 14.0 : 16.0);
    final spacing = isMobile ? 12.0 : (isTablet ? 14.0 : 16.0);

    return Form(
      key: widget.controller.paymentFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, isMobile: isMobile, cardPadding: cardPadding),
          SizedBox(height: spacing),
          _buildPaymentTypeSelector(context, isMobile: isMobile, isTablet: isTablet, cardPadding: cardPadding),
          SizedBox(height: spacing),
          _buildAmountField(context, isMobile: isMobile, isTablet: isTablet, cardPadding: cardPadding),
          SizedBox(height: spacing),
          _buildReferenceField(context, isMobile: isMobile, isTablet: isTablet, cardPadding: cardPadding),
          SizedBox(height: spacing * 1.2),
          _buildActions(context, isMobile: isMobile, isTablet: isTablet),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, {
    required bool isMobile,
    required double cardPadding,
  }) {
    final remainingBalance = widget.controller.invoice!.balanceDue;
    final titleSize = isMobile ? 16.0 : 18.0;
    final subtitleSize = isMobile ? 12.0 : 13.0;
    final iconSize = isMobile ? 20.0 : 22.0;

    return Container(
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 8 : 10),
            decoration: BoxDecoration(
              color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.payment,
              color: ElegantLightTheme.primaryBlue,
              size: iconSize,
            ),
          ),
          SizedBox(width: isMobile ? 10 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Registrar Pago',
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w700,
                    color: ElegantLightTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Saldo: ${AppFormatters.formatCurrency(remainingBalance)}',
                  style: TextStyle(
                    fontSize: subtitleSize,
                    fontWeight: FontWeight.w500,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: widget.onCancel,
            icon: Icon(
              Icons.close,
              color: ElegantLightTheme.textSecondary,
              size: iconSize,
            ),
            style: IconButton.styleFrom(
              backgroundColor: ElegantLightTheme.textSecondary.withValues(alpha: 0.1),
              padding: EdgeInsets.all(isMobile ? 6 : 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentTypeSelector(BuildContext context, {
    required bool isMobile,
    required bool isTablet,
    required double cardPadding,
  }) {
    final labelSize = isMobile ? 13.0 : 14.0;

    return Container(
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: ElegantLightTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet,
                color: ElegantLightTheme.primaryBlue,
                size: isMobile ? 18 : 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Método de Pago',
                style: TextStyle(
                  fontSize: labelSize,
                  fontWeight: FontWeight.w600,
                  color: ElegantLightTheme.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 10 : 12),

          // Toggle: Efectivo / Cuenta Bancaria
          _buildPaymentTypeToggle(context, isMobile: isMobile),

          // Mostrar selector de cuenta bancaria solo si es el tipo seleccionado
          if (_paymentType == _PaymentType.bankAccount) ...[
            SizedBox(height: isMobile ? 10 : 12),
            BankAccountSelector(
              selectedAccount: _selectedAccount,
              onAccountSelected: (account) {
                setState(() {
                  _selectedAccount = account;
                });

                if (account != null) {
                  final paymentMethod = _getPaymentMethodFromAccount(account);
                  widget.controller.setPaymentMethod(paymentMethod);
                  widget.controller.setBankAccountId(account.id);
                } else {
                  widget.controller.setBankAccountId(null);
                }
              },
              hintText: 'Seleccionar cuenta de pago',
              isRequired: true,
            ),

            // Información de la cuenta seleccionada
            if (_selectedAccount != null) ...[
              SizedBox(height: isMobile ? 8 : 10),
              Container(
                padding: EdgeInsets.all(isMobile ? 8 : 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF10B981).withValues(alpha: 0.1),
                      const Color(0xFF10B981).withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: const Color(0xFF10B981),
                      size: isMobile ? 16 : 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'El pago se registrará en "${_selectedAccount!.name}"',
                        style: TextStyle(
                          fontSize: isMobile ? 11 : 12,
                          color: const Color(0xFF10B981),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],

          // Confirmación visual cuando se selecciona efectivo
          if (_paymentType == _PaymentType.cash) ...[
            SizedBox(height: isMobile ? 8 : 10),
            Container(
              padding: EdgeInsets.all(isMobile ? 8 : 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.green.withValues(alpha: 0.1),
                    Colors.green.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.green.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.payments,
                    color: Colors.green.shade700,
                    size: isMobile ? 16 : 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pago en efectivo - sin cuenta bancaria asociada',
                      style: TextStyle(
                        fontSize: isMobile ? 11 : 12,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                      ),
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

  /// Toggle segmentado para seleccionar tipo de pago
  Widget _buildPaymentTypeToggle(BuildContext context, {required bool isMobile}) {
    final fontSize = isMobile ? 12.0 : 13.0;
    final iconSize = isMobile ? 16.0 : 18.0;

    return Container(
      decoration: BoxDecoration(
        color: ElegantLightTheme.textTertiary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          // Opción: Efectivo
          Expanded(
            child: _buildToggleOption(
              label: 'Efectivo',
              icon: Icons.money,
              isSelected: _paymentType == _PaymentType.cash,
              onTap: () {
                setState(() {
                  _paymentType = _PaymentType.cash;
                  _selectedAccount = null;
                });
                widget.controller.setPaymentMethod(PaymentMethod.cash);
                widget.controller.setBankAccountId(null);
              },
              fontSize: fontSize,
              iconSize: iconSize,
              selectedColor: Colors.green,
            ),
          ),
          const SizedBox(width: 3),
          // Opción: Cuenta Bancaria
          Expanded(
            child: _buildToggleOption(
              label: 'Cuenta Bancaria',
              icon: Icons.account_balance,
              isSelected: _paymentType == _PaymentType.bankAccount,
              onTap: () {
                setState(() {
                  _paymentType = _PaymentType.bankAccount;
                });
              },
              fontSize: fontSize,
              iconSize: iconSize,
              selectedColor: ElegantLightTheme.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required double fontSize,
    required double iconSize,
    required Color selectedColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: selectedColor.withValues(alpha: 0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: iconSize,
              color: isSelected ? selectedColor : ElegantLightTheme.textTertiary,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? selectedColor : ElegantLightTheme.textTertiary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Convierte el tipo de cuenta bancaria al PaymentMethod correspondiente
  PaymentMethod _getPaymentMethodFromAccount(BankAccount account) {
    switch (account.type) {
      case BankAccountType.cash:
        return PaymentMethod.cash;
      case BankAccountType.creditCard:
        return PaymentMethod.creditCard;
      case BankAccountType.debitCard:
        return PaymentMethod.debitCard;
      case BankAccountType.digitalWallet:
      case BankAccountType.savings:
      case BankAccountType.checking:
        return PaymentMethod.bankTransfer;
      case BankAccountType.other:
        return PaymentMethod.other;
    }
  }

  Widget _buildAmountField(BuildContext context, {
    required bool isMobile,
    required bool isTablet,
    required double cardPadding,
  }) {
    final labelSize = isMobile ? 13.0 : 14.0;
    final inputSize = isMobile ? 14.0 : 15.0;

    return Container(
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: ElegantLightTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.attach_money,
                color: Colors.green,
                size: isMobile ? 18 : 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Monto del Pago',
                style: TextStyle(
                  fontSize: labelSize,
                  fontWeight: FontWeight.w600,
                  color: ElegantLightTheme.textPrimary,
                ),
              ),
              const Spacer(),
              // Botón de pago completo
              TextButton(
                onPressed: () {
                  // Formatear el valor con separadores de miles
                  widget.controller.paymentAmountController.text =
                      NumberInputFormatter.formatValueForDisplay(
                        widget.controller.invoice!.balanceDue,
                        allowDecimals: true,
                      );
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Pago completo',
                  style: TextStyle(
                    fontSize: isMobile ? 11 : 12,
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 8 : 10),
          TextFormField(
            controller: widget.controller.paymentAmountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              // Formatter con separadores de miles y decimales opcionales
              NumberInputFormatter(allowDecimals: true, maxDecimalPlaces: 2),
            ],
            style: TextStyle(
              fontSize: inputSize,
              fontWeight: FontWeight.w600,
              color: ElegantLightTheme.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: TextStyle(
                color: ElegantLightTheme.textTertiary,
                fontSize: inputSize,
              ),
              prefixText: '\$ ',
              prefixStyle: TextStyle(
                color: Colors.green,
                fontSize: inputSize,
                fontWeight: FontWeight.w700,
              ),
              filled: true,
              fillColor: Colors.white,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: isMobile ? 12 : 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: ElegantLightTheme.textTertiary.withValues(alpha: 0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: ElegantLightTheme.textTertiary.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.green, width: 1.5),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Ingrese el monto';
              }
              // Usar el método estático para obtener el valor numérico del texto formateado
              final amount = NumberInputFormatter.getNumericValue(value);
              if (amount == null || amount <= 0) {
                return 'Monto inválido';
              }
              if (amount > widget.controller.invoice!.balanceDue) {
                return 'Excede el saldo pendiente';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReferenceField(BuildContext context, {
    required bool isMobile,
    required bool isTablet,
    required double cardPadding,
  }) {
    final labelSize = isMobile ? 13.0 : 14.0;
    final inputSize = isMobile ? 13.0 : 14.0;

    return Container(
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: ElegantLightTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.receipt_long,
                color: ElegantLightTheme.textSecondary,
                size: isMobile ? 18 : 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Referencia',
                style: TextStyle(
                  fontSize: labelSize,
                  fontWeight: FontWeight.w600,
                  color: ElegantLightTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '(Opcional)',
                style: TextStyle(
                  fontSize: isMobile ? 11 : 12,
                  color: ElegantLightTheme.textTertiary,
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 8 : 10),
          TextFormField(
            controller: widget.controller.paymentReferenceController,
            style: TextStyle(
              fontSize: inputSize,
              color: ElegantLightTheme.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Nro. transferencia, comprobante, etc.',
              hintStyle: TextStyle(
                color: ElegantLightTheme.textTertiary,
                fontSize: isMobile ? 12 : 13,
              ),
              filled: true,
              fillColor: Colors.white,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: isMobile ? 12 : 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: ElegantLightTheme.textTertiary.withValues(alpha: 0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: ElegantLightTheme.textTertiary.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: ElegantLightTheme.primaryBlue,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Determina si el botón Confirmar debe estar habilitado
  bool get _canSubmit {
    if (_paymentType == _PaymentType.cash) return true;
    return _selectedAccount != null;
  }

  Widget _buildActions(BuildContext context, {
    required bool isMobile,
    required bool isTablet,
  }) {
    final buttonHeight = isMobile ? 46.0 : 48.0;
    final fontSize = isMobile ? 14.0 : 15.0;
    final iconSize = isMobile ? 18.0 : 20.0;

    // Color verde consistente con el tema
    const successColor = Color(0xFF10B981);

    return Row(
      children: [
        // Botón Cancelar
        Expanded(
          child: SizedBox(
            height: buttonHeight,
            child: OutlinedButton(
              onPressed: widget.onCancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: ElegantLightTheme.textSecondary,
                side: BorderSide(
                  color: ElegantLightTheme.textTertiary.withValues(alpha: 0.3),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.close, size: iconSize),
                  const SizedBox(width: 6),
                  Text(
                    'Cancelar',
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Botón Confirmar
        Expanded(
          child: SizedBox(
            height: buttonHeight,
            child: ElevatedButton(
              onPressed: _canSubmit ? widget.onSubmit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: successColor,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check, size: iconSize, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    isMobile ? 'Confirmar' : 'Confirmar Pago',
                    style: TextStyle(
                      fontSize: fontSize,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
