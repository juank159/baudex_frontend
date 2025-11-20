// lib/features/invoices/presentation/widgets/invoice_payment_form_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get_state_manager/src/simple/get_state.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../controllers/invoice_detail_controller.dart';
import '../../domain/entities/invoice.dart';

class InvoicePaymentFormWidget extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);
    final isDesktop = Responsive.isDesktop(context);
    
    // Tamaños responsivos
    final spacing = isMobile ? 16.0 : isTablet ? 20.0 : 24.0;
    
    return Form(
      key: controller.paymentFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFuturisticHeader(context, isMobile: isMobile, isTablet: isTablet, isDesktop: isDesktop),
          SizedBox(height: spacing),
          _buildFuturisticPaymentMethodSelector(context, isMobile: isMobile, isTablet: isTablet, isDesktop: isDesktop),
          SizedBox(height: spacing),
          _buildFuturisticAmountField(context, isMobile: isMobile, isTablet: isTablet, isDesktop: isDesktop),
          SizedBox(height: spacing),
          _buildFuturisticReferenceField(context, isMobile: isMobile, isTablet: isTablet, isDesktop: isDesktop),
          SizedBox(height: spacing),
          _buildFuturisticNotesField(context, isMobile: isMobile, isTablet: isTablet, isDesktop: isDesktop),
          SizedBox(height: spacing * 1.5),
          _buildFuturisticActions(context, isMobile: isMobile, isTablet: isTablet, isDesktop: isDesktop),
        ],
      ),
    );
  }

  Widget _buildFuturisticHeader(BuildContext context, {
    required bool isMobile,
    required bool isTablet, 
    required bool isDesktop,
  }) {
    final titleSize = isMobile ? 20.0 : isTablet ? 22.0 : 18.0;
    final subtitleSize = isMobile ? 14.0 : isTablet ? 16.0 : 12.0;
    final iconSize = isMobile ? 24.0 : isTablet ? 28.0 : 22.0;
    final remainingBalance = controller.invoice!.balanceDue;
    
    return Container(
      padding: EdgeInsets.all(isMobile ? 16.0 : isTablet ? 20.0 : 18.0),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.glassGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ElegantLightTheme.primaryGradient.colors.first.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 8.0 : isTablet ? 10.0 : 8.0),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.successGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: ElegantLightTheme.glowShadow,
                ),
                child: Icon(
                  Icons.payment,
                  color: Colors.white,
                  size: iconSize,
                ),
              ),
              SizedBox(width: isMobile ? 12.0 : isTablet ? 16.0 : 14.0),
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
                    SizedBox(height: 4),
                    Text(
                      'Saldo pendiente: ${AppFormatters.formatCurrency(remainingBalance)}',
                      style: TextStyle(
                        fontSize: subtitleSize,
                        fontWeight: FontWeight.w500,
                        color: ElegantLightTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onCancel,
                icon: Icon(
                  Icons.close,
                  color: ElegantLightTheme.textSecondary,
                  size: iconSize,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: ElegantLightTheme.textSecondary.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFuturisticPaymentMethodSelector(BuildContext context, {
    required bool isMobile,
    required bool isTablet, 
    required bool isDesktop,
  }) {
    final textSize = isMobile ? 16.0 : isTablet ? 18.0 : 14.0;
    final spacing = isMobile ? 12.0 : isTablet ? 16.0 : 14.0;
    
    return Container(
      padding: EdgeInsets.all(isMobile ? 16.0 : isTablet ? 20.0 : 18.0),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.glassGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ElegantLightTheme.infoGradient.colors.first.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.credit_card,
                color: ElegantLightTheme.infoGradient.colors.first,
                size: isMobile ? 20.0 : isTablet ? 22.0 : 18.0,
              ),
              SizedBox(width: 8),
              Text(
                'Método de Pago',
                style: TextStyle(
                  fontSize: textSize,
                  fontWeight: FontWeight.w600,
                  color: ElegantLightTheme.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: spacing),
          GetBuilder<InvoiceDetailController>(
            builder: (controller) {
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: PaymentMethod.values.map((method) {
                  final isSelected = controller.selectedPaymentMethod == method;
                  return GestureDetector(
                    onTap: () => controller.setPaymentMethod(method),
                    child: AnimatedContainer(
                      duration: ElegantLightTheme.normalAnimation,
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 12.0 : isTablet ? 16.0 : 14.0,
                        vertical: isMobile ? 8.0 : isTablet ? 10.0 : 8.0,
                      ),
                      decoration: BoxDecoration(
                        gradient: isSelected 
                          ? ElegantLightTheme.primaryGradient 
                          : ElegantLightTheme.glassGradient,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected 
                            ? ElegantLightTheme.primaryGradient.colors.first
                            : ElegantLightTheme.textTertiary.withValues(alpha: 0.3),
                          width: 1,
                        ),
                        boxShadow: isSelected ? ElegantLightTheme.glowShadow : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            method.icon,
                            color: isSelected ? Colors.white : ElegantLightTheme.textPrimary,
                            size: isMobile ? 16.0 : isTablet ? 18.0 : 14.0,
                          ),
                          SizedBox(width: 6),
                          Text(
                            method.displayName,
                            style: TextStyle(
                              color: isSelected ? Colors.white : ElegantLightTheme.textPrimary,
                              fontSize: isMobile ? 14.0 : isTablet ? 16.0 : 12.0,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFuturisticAmountField(BuildContext context, {
    required bool isMobile,
    required bool isTablet, 
    required bool isDesktop,
  }) {
    final textSize = isMobile ? 16.0 : isTablet ? 18.0 : 14.0;
    final spacing = isMobile ? 12.0 : isTablet ? 16.0 : 14.0;
    
    return Container(
      padding: EdgeInsets.all(isMobile ? 16.0 : isTablet ? 20.0 : 18.0),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.glassGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ElegantLightTheme.successGradient.colors.first.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.attach_money,
                color: ElegantLightTheme.successGradient.colors.first,
                size: isMobile ? 20.0 : isTablet ? 22.0 : 18.0,
              ),
              SizedBox(width: 8),
              Text(
                'Monto del Pago',
                style: TextStyle(
                  fontSize: textSize,
                  fontWeight: FontWeight.w600,
                  color: ElegantLightTheme.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: spacing),
          TextFormField(
            controller: controller.paymentAmountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            style: TextStyle(
              fontSize: textSize,
              fontWeight: FontWeight.w600,
              color: ElegantLightTheme.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: '0.00',
              hintStyle: TextStyle(
                color: ElegantLightTheme.textTertiary,
                fontSize: textSize,
              ),
              prefixText: '\$ ',
              prefixStyle: TextStyle(
                color: ElegantLightTheme.successGradient.colors.first,
                fontSize: textSize,
                fontWeight: FontWeight.w700,
              ),
              filled: true,
              fillColor: ElegantLightTheme.backgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: ElegantLightTheme.textTertiary.withValues(alpha: 0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: ElegantLightTheme.textTertiary.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: ElegantLightTheme.successGradient.colors.first,
                  width: 2,
                ),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: isMobile ? 16.0 : isTablet ? 18.0 : 14.0,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Ingrese el monto del pago';
              }
              final amount = double.tryParse(value);
              if (amount == null || amount <= 0) {
                return 'Ingrese un monto válido';
              }
              if (amount > controller.invoice!.balanceDue) {
                return 'El monto no puede superar el saldo pendiente';
              }
              return null;
            },
          ),
          SizedBox(height: 8),
          Row(
            children: [
              TextButton.icon(
                onPressed: () {
                  controller.paymentAmountController.text = 
                    controller.invoice!.balanceDue.toStringAsFixed(2);
                },
                icon: Icon(
                  Icons.check_circle_outline,
                  size: isMobile ? 16.0 : isTablet ? 18.0 : 14.0,
                  color: ElegantLightTheme.successGradient.colors.first,
                ),
                label: Text(
                  'Pago completo',
                  style: TextStyle(
                    fontSize: isMobile ? 12.0 : isTablet ? 14.0 : 11.0,
                    color: ElegantLightTheme.successGradient.colors.first,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFuturisticReferenceField(BuildContext context, {
    required bool isMobile,
    required bool isTablet, 
    required bool isDesktop,
  }) {
    final textSize = isMobile ? 16.0 : isTablet ? 18.0 : 14.0;
    final spacing = isMobile ? 12.0 : isTablet ? 16.0 : 14.0;
    
    return Container(
      padding: EdgeInsets.all(isMobile ? 16.0 : isTablet ? 20.0 : 18.0),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.glassGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ElegantLightTheme.warningGradient.colors.first.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.receipt_long,
                color: ElegantLightTheme.warningGradient.colors.first,
                size: isMobile ? 20.0 : isTablet ? 22.0 : 18.0,
              ),
              SizedBox(width: 8),
              Text(
                'Referencia (Opcional)',
                style: TextStyle(
                  fontSize: textSize,
                  fontWeight: FontWeight.w600,
                  color: ElegantLightTheme.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: spacing),
          TextFormField(
            controller: controller.paymentReferenceController,
            style: TextStyle(
              fontSize: textSize,
              color: ElegantLightTheme.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Número de transferencia, cheque, etc.',
              hintStyle: TextStyle(
                color: ElegantLightTheme.textTertiary,
                fontSize: isMobile ? 14.0 : isTablet ? 16.0 : 12.0,
              ),
              filled: true,
              fillColor: ElegantLightTheme.backgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: ElegantLightTheme.textTertiary.withValues(alpha: 0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: ElegantLightTheme.textTertiary.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: ElegantLightTheme.warningGradient.colors.first,
                  width: 2,
                ),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: isMobile ? 16.0 : isTablet ? 18.0 : 14.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFuturisticNotesField(BuildContext context, {
    required bool isMobile,
    required bool isTablet, 
    required bool isDesktop,
  }) {
    final textSize = isMobile ? 16.0 : isTablet ? 18.0 : 14.0;
    final spacing = isMobile ? 12.0 : isTablet ? 16.0 : 14.0;
    
    return Container(
      padding: EdgeInsets.all(isMobile ? 16.0 : isTablet ? 20.0 : 18.0),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.glassGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ElegantLightTheme.textTertiary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.note_alt_outlined,
                color: ElegantLightTheme.textSecondary,
                size: isMobile ? 20.0 : isTablet ? 22.0 : 18.0,
              ),
              SizedBox(width: 8),
              Text(
                'Notas (Opcional)',
                style: TextStyle(
                  fontSize: textSize,
                  fontWeight: FontWeight.w600,
                  color: ElegantLightTheme.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: spacing),
          TextFormField(
            controller: controller.paymentNotesController,
            maxLines: 3,
            style: TextStyle(
              fontSize: textSize,
              color: ElegantLightTheme.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Observaciones adicionales sobre el pago...',
              hintStyle: TextStyle(
                color: ElegantLightTheme.textTertiary,
                fontSize: isMobile ? 14.0 : isTablet ? 16.0 : 12.0,
              ),
              filled: true,
              fillColor: ElegantLightTheme.backgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: ElegantLightTheme.textTertiary.withValues(alpha: 0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: ElegantLightTheme.textTertiary.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: ElegantLightTheme.textSecondary,
                  width: 2,
                ),
              ),
              contentPadding: EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFuturisticActions(BuildContext context, {
    required bool isMobile,
    required bool isTablet, 
    required bool isDesktop,
  }) {
    final spacing = isMobile ? 12.0 : isTablet ? 16.0 : 14.0;
    
    return Row(
      children: [
        Expanded(
          child: Container(
            height: isMobile ? 50.0 : isTablet ? 55.0 : 48.0,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: ElegantLightTheme.textTertiary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: TextButton.icon(
              onPressed: onCancel,
              icon: Icon(
                Icons.close,
                color: ElegantLightTheme.textSecondary,
                size: isMobile ? 18.0 : isTablet ? 20.0 : 16.0,
              ),
              label: Text(
                'Cancelar',
                style: TextStyle(
                  color: ElegantLightTheme.textSecondary,
                  fontSize: isMobile ? 16.0 : isTablet ? 18.0 : 14.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: spacing),
        Expanded(
          flex: 2,
          child: Container(
            height: isMobile ? 50.0 : isTablet ? 55.0 : 48.0,
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.successGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: ElegantLightTheme.glowShadow,
            ),
            child: ElevatedButton.icon(
              onPressed: onSubmit,
              icon: Icon(
                Icons.check,
                color: Colors.white,
                size: isMobile ? 18.0 : isTablet ? 20.0 : 16.0,
              ),
              label: Text(
                'Confirmar Pago',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isMobile ? 16.0 : isTablet ? 18.0 : 14.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}