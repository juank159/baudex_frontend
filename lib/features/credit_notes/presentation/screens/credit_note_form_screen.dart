// lib/features/credit_notes/presentation/screens/credit_note_form_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../domain/entities/credit_note.dart';
import '../controllers/credit_note_form_controller.dart';
import '../widgets/credit_note_item_dialog.dart';

class CreditNoteFormScreen extends GetView<CreditNoteFormController> {
  const CreditNoteFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    final isTablet = size.width >= 600 && size.width < 1024;

    return Scaffold(
      backgroundColor: ElegantLightTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: ElegantLightTheme.primaryGradient,
            boxShadow: [
              BoxShadow(
                color: ElegantLightTheme.primaryGradient.colors.first.withValues(
                  alpha: 0.3,
                ),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
        title: Obx(() => Text(
              controller.isEditMode
                  ? 'Editar Nota de Crédito'
                  : 'Nueva Nota de Crédito',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: isMobile ? 16 : 20,
              ),
            )),
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: ElegantLightTheme.glassGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Get.back(),
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      ElegantLightTheme.primaryGradient.colors.first,
                    ),
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Cargando...',
                  style: TextStyle(
                    color: ElegantLightTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        return Form(
          key: controller.formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 12 : isTablet ? 16 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (controller.invoice != null)
                  _buildInvoiceInfo(isMobile, isTablet),
                SizedBox(height: isMobile ? 12 : 16),
                _buildBasicInfo(isMobile, isTablet),
                SizedBox(height: isMobile ? 12 : 16),
                _buildTypeAndReason(isMobile, isTablet),
                SizedBox(height: isMobile ? 12 : 16),
                _buildItemsSection(isMobile, isTablet),
                SizedBox(height: isMobile ? 12 : 16),
                _buildTotals(isMobile, isTablet),
                SizedBox(height: isMobile ? 12 : 16),
                _buildNotesAndTerms(isMobile, isTablet),
                SizedBox(height: isMobile ? 24 : 32),
                _buildActions(isMobile, isTablet),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildInvoiceInfo(bool isMobile, bool isTablet) {
    final titleSize = isMobile ? 14.0 : isTablet ? 16.0 : 15.0;
    final textSize = isMobile ? 12.0 : isTablet ? 14.0 : 13.0;
    final amountSize = isMobile ? 16.0 : isTablet ? 20.0 : 18.0;
    final padding = isMobile ? 12.0 : isTablet ? 16.0 : 14.0;

    return FuturisticContainer(
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Obx(() {
          final invoice = controller.invoice;
          if (invoice == null) return const SizedBox.shrink();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: ElegantLightTheme.infoGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.receipt_long,
                      color: Colors.white,
                      size: titleSize + 4,
                    ),
                  ),
                  SizedBox(width: padding),
                  Text(
                    'Factura de Referencia',
                    style: TextStyle(
                      fontSize: titleSize,
                      fontWeight: FontWeight.w700,
                      color: ElegantLightTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: padding),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          invoice.number,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: textSize + 1,
                            color: ElegantLightTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          invoice.customerName,
                          style: TextStyle(
                            color: ElegantLightTheme.textSecondary,
                            fontSize: textSize,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        AppFormatters.formatCurrency(invoice.total),
                        style: TextStyle(
                          fontSize: amountSize,
                          fontWeight: FontWeight.w700,
                          foreground: Paint()
                            ..shader = ElegantLightTheme.primaryGradient
                                .createShader(const Rect.fromLTWH(0, 0, 200, 70)),
                        ),
                      ),
                      if (controller.remainingCreditableAmount > 0) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: ElegantLightTheme.successGradient.colors.first
                                .withValues(alpha:0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: ElegantLightTheme.successGradient.colors.first
                                  .withValues(alpha:0.3),
                            ),
                          ),
                          child: Text(
                            'Acreditable: ${AppFormatters.formatCurrency(controller.remainingCreditableAmount)}',
                            style: TextStyle(
                              color: ElegantLightTheme.successGradient.colors.first,
                              fontSize: textSize - 1,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildBasicInfo(bool isMobile, bool isTablet) {
    final titleSize = isMobile ? 14.0 : isTablet ? 16.0 : 15.0;
    final textSize = isMobile ? 12.0 : isTablet ? 14.0 : 13.0;
    final padding = isMobile ? 12.0 : isTablet ? 16.0 : 14.0;

    return FuturisticContainer(
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: titleSize + 2,
                  color: ElegantLightTheme.primaryGradient.colors.first,
                ),
                SizedBox(width: padding / 2),
                Text(
                  'Información Básica',
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w700,
                    color: ElegantLightTheme.textPrimary,
                  ),
                ),
              ],
            ),
            SizedBox(height: padding),
            TextFormField(
              controller: controller.numberController,
              style: TextStyle(
                fontSize: textSize,
                color: ElegantLightTheme.textPrimary,
              ),
              decoration: InputDecoration(
                labelText: 'Número (Opcional)',
                labelStyle: TextStyle(
                  color: ElegantLightTheme.textSecondary,
                  fontSize: textSize,
                ),
                hintText: 'Se generará automáticamente',
                hintStyle: TextStyle(
                  color: ElegantLightTheme.textTertiary,
                  fontSize: textSize - 1,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: ElegantLightTheme.textTertiary.withValues(alpha:0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: ElegantLightTheme.textTertiary.withValues(alpha:0.2),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: ElegantLightTheme.primaryGradient.colors.first,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: ElegantLightTheme.surfaceColor,
              ),
            ),
            SizedBox(height: padding),
            Obx(() => InkWell(
                  onTap: _selectDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: EdgeInsets.all(padding),
                    decoration: BoxDecoration(
                      color: ElegantLightTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: ElegantLightTheme.textTertiary.withValues(alpha:0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Fecha',
                              style: TextStyle(
                                fontSize: textSize - 1,
                                color: ElegantLightTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppFormatters.formatDate(controller.date),
                              style: TextStyle(
                                fontSize: textSize,
                                fontWeight: FontWeight.w600,
                                color: ElegantLightTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: ElegantLightTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.calendar_today,
                            color: Colors.white,
                            size: textSize + 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeAndReason(bool isMobile, bool isTablet) {
    final titleSize = isMobile ? 14.0 : isTablet ? 16.0 : 15.0;
    final textSize = isMobile ? 11.0 : isTablet ? 13.0 : 12.0;
    final padding = isMobile ? 12.0 : isTablet ? 16.0 : 14.0;

    // Ancho fijo para botones de tipo (basado en "Completa")
    final typeButtonMinWidth = isMobile ? 100.0 : isTablet ? 120.0 : 110.0;

    return FuturisticContainer(
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.category_outlined,
                  size: titleSize + 2,
                  color: ElegantLightTheme.warningGradient.colors.first,
                ),
                SizedBox(width: padding / 2),
                Text(
                  'Tipo y Razón',
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w700,
                    color: ElegantLightTheme.textPrimary,
                  ),
                ),
              ],
            ),
            SizedBox(height: padding),
            Text(
              'Tipo de Nota de Crédito',
              style: TextStyle(
                fontSize: textSize + 1,
                fontWeight: FontWeight.w600,
                color: ElegantLightTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Obx(() => Row(
                  children: CreditNoteType.values.map((type) {
                    final isSelected = controller.selectedType == type;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () => controller.setType(type),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: typeButtonMinWidth,
                          padding: EdgeInsets.symmetric(
                            horizontal: padding,
                            vertical: padding * 0.8,
                          ),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? ElegantLightTheme.primaryGradient
                                : null,
                            color: isSelected
                                ? null
                                : ElegantLightTheme.cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.transparent
                                  : ElegantLightTheme.textTertiary.withValues(alpha:0.3),
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: ElegantLightTheme.primaryGradient.colors.first
                                          .withValues(alpha:0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              type.displayName,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : ElegantLightTheme.textPrimary,
                                fontSize: textSize + 1,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                )),
            SizedBox(height: padding * 1.2),
            Text(
              'Razón',
              style: TextStyle(
                fontSize: textSize + 1,
                fontWeight: FontWeight.w600,
                color: ElegantLightTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Obx(() {
              // Ancho fijo basado en "Insatisfacción del Cliente" (el texto más largo)
              final reasonButtonWidth = isMobile ? 200.0 : isTablet ? 230.0 : 220.0;

              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: CreditNoteReason.values.map((reason) {
                  final isSelected = controller.selectedReason == reason;
                  return InkWell(
                    onTap: () => controller.setReason(reason),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: reasonButtonWidth,
                      padding: EdgeInsets.symmetric(
                        horizontal: padding * 0.8,
                        vertical: padding * 0.7,
                      ),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? ElegantLightTheme.infoGradient
                            : null,
                        color: isSelected
                            ? null
                            : ElegantLightTheme.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : ElegantLightTheme.textTertiary.withValues(alpha:0.3),
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: ElegantLightTheme.infoGradient.colors.first
                                      .withValues(alpha:0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            reason.icon,
                            size: textSize + 2,
                            color: isSelected
                                ? Colors.white
                                : ElegantLightTheme.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              reason.displayName,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : ElegantLightTheme.textPrimary,
                                fontSize: textSize,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsSection(bool isMobile, bool isTablet) {
    final titleSize = isMobile ? 14.0 : isTablet ? 16.0 : 15.0;
    final textSize = isMobile ? 12.0 : isTablet ? 14.0 : 13.0;
    final padding = isMobile ? 12.0 : isTablet ? 16.0 : 14.0;

    return FuturisticContainer(
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: titleSize + 2,
                      color: ElegantLightTheme.successGradient.colors.first,
                    ),
                    SizedBox(width: padding / 2),
                    Text(
                      'Items',
                      style: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.w700,
                        color: ElegantLightTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.successGradient,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: ElegantLightTheme.successGradient.colors.first
                            .withValues(alpha:0.3),
                        offset: const Offset(0, 2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _addItem,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: padding,
                          vertical: padding / 2,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add,
                              color: Colors.white,
                              size: textSize + 4,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Agregar',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: textSize,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: padding),
            Obx(() {
              if (controller.items.isEmpty) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(padding * 2),
                    child: Column(
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 48,
                          color: ElegantLightTheme.textTertiary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No hay items agregados',
                          style: TextStyle(
                            color: ElegantLightTheme.textSecondary,
                            fontSize: textSize,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: controller.items.length,
                separatorBuilder: (context, index) => Divider(
                  height: padding * 1.5,
                  color: ElegantLightTheme.textTertiary.withValues(alpha:0.2),
                ),
                itemBuilder: (context, index) {
                  final item = controller.items[index];
                  return Container(
                    padding: EdgeInsets.all(padding / 1.5),
                    decoration: BoxDecoration(
                      color: ElegantLightTheme.cardColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.description,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: textSize,
                                  color: ElegantLightTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${item.quantity} x ${AppFormatters.formatCurrency(item.unitPrice)}',
                                style: TextStyle(
                                  color: ElegantLightTheme.textSecondary,
                                  fontSize: textSize - 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          AppFormatters.formatCurrency(item.subtotal),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: textSize + 1,
                            color: ElegantLightTheme.textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          color: ElegantLightTheme.primaryGradient.colors.first,
                          onPressed: () => _editItem(index),
                          iconSize: textSize + 6,
                          tooltip: 'Editar',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          color: ElegantLightTheme.errorGradient.colors.first,
                          onPressed: () => controller.removeItem(index),
                          iconSize: textSize + 6,
                          tooltip: 'Eliminar',
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTotals(bool isMobile, bool isTablet) {
    final titleSize = isMobile ? 14.0 : isTablet ? 16.0 : 15.0;
    final textSize = isMobile ? 12.0 : isTablet ? 14.0 : 13.0;
    final amountSize = isMobile ? 18.0 : isTablet ? 22.0 : 20.0;
    final padding = isMobile ? 12.0 : isTablet ? 16.0 : 14.0;

    return FuturisticContainer(
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Obx(() => Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calculate_outlined,
                      size: titleSize + 2,
                      color: ElegantLightTheme.warningGradient.colors.first,
                    ),
                    SizedBox(width: padding / 2),
                    Text(
                      'Totales',
                      style: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.w700,
                        color: ElegantLightTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: padding),
                _buildTotalRow('Subtotal', controller.subtotal, textSize, false),
                SizedBox(height: padding),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'IVA',
                      style: TextStyle(
                        fontSize: textSize,
                        color: ElegantLightTheme.textSecondary,
                      ),
                    ),
                    Row(
                      children: [
                        SizedBox(
                          width: 70,
                          child: TextFormField(
                            initialValue: controller.taxPercentage.toString(),
                            keyboardType: TextInputType.number,
                            style: TextStyle(
                              fontSize: textSize,
                              color: ElegantLightTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              suffixText: '%',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: ElegantLightTheme.textTertiary
                                      .withValues(alpha:0.3),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: ElegantLightTheme
                                      .primaryGradient.colors.first,
                                  width: 2,
                                ),
                              ),
                            ),
                            onChanged: (value) {
                              final percent = double.tryParse(value);
                              if (percent != null) {
                                controller.setTaxPercentage(percent);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          AppFormatters.formatCurrency(controller.taxAmount),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: textSize,
                            color: ElegantLightTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Divider(
                  height: padding * 2,
                  thickness: 2,
                  color: ElegantLightTheme.textTertiary.withValues(alpha:0.2),
                ),
                _buildTotalRow('Total', controller.total, amountSize, true),
              ],
            )),
      ),
    );
  }

  Widget _buildTotalRow(
    String label,
    double amount,
    double fontSize,
    bool isTotal,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
            color: isTotal
                ? ElegantLightTheme.textPrimary
                : ElegantLightTheme.textSecondary,
          ),
        ),
        Text(
          AppFormatters.formatCurrency(amount),
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            foreground: isTotal
                ? (Paint()
                  ..shader = ElegantLightTheme.successGradient.createShader(
                    const Rect.fromLTWH(0, 0, 200, 70),
                  ))
                : null,
            color: isTotal ? null : ElegantLightTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildNotesAndTerms(bool isMobile, bool isTablet) {
    final titleSize = isMobile ? 14.0 : isTablet ? 16.0 : 15.0;
    final textSize = isMobile ? 12.0 : isTablet ? 14.0 : 13.0;
    final padding = isMobile ? 12.0 : isTablet ? 16.0 : 14.0;

    return FuturisticContainer(
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.notes_outlined,
                  size: titleSize + 2,
                  color: ElegantLightTheme.infoGradient.colors.first,
                ),
                SizedBox(width: padding / 2),
                Text(
                  'Información Adicional',
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w700,
                    color: ElegantLightTheme.textPrimary,
                  ),
                ),
              ],
            ),
            SizedBox(height: padding),
            TextFormField(
              controller: controller.notesController,
              style: TextStyle(
                fontSize: textSize,
                color: ElegantLightTheme.textPrimary,
              ),
              decoration: InputDecoration(
                labelText: 'Notas (Opcional)',
                labelStyle: TextStyle(
                  color: ElegantLightTheme.textSecondary,
                  fontSize: textSize,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: ElegantLightTheme.textTertiary.withValues(alpha:0.2),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: ElegantLightTheme.primaryGradient.colors.first,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: ElegantLightTheme.surfaceColor,
              ),
              maxLines: 3,
            ),
            SizedBox(height: padding),
            TextFormField(
              controller: controller.termsController,
              style: TextStyle(
                fontSize: textSize,
                color: ElegantLightTheme.textPrimary,
              ),
              decoration: InputDecoration(
                labelText: 'Términos (Opcional)',
                labelStyle: TextStyle(
                  color: ElegantLightTheme.textSecondary,
                  fontSize: textSize,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: ElegantLightTheme.textTertiary.withValues(alpha:0.2),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: ElegantLightTheme.primaryGradient.colors.first,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: ElegantLightTheme.surfaceColor,
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(bool isMobile, bool isTablet) {
    final padding = isMobile ? 12.0 : isTablet ? 16.0 : 14.0;
    final buttonHeight = isMobile ? 48.0 : isTablet ? 56.0 : 52.0;
    final fontSize = isMobile ? 14.0 : isTablet ? 16.0 : 15.0;

    return Obx(() {
      if (controller.isSaving) {
        return Center(
          child: Column(
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    ElegantLightTheme.primaryGradient.colors.first,
                  ),
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Guardando...',
                style: TextStyle(
                  color: ElegantLightTheme.textSecondary,
                  fontSize: fontSize - 2,
                ),
              ),
            ],
          ),
        );
      }

      return Row(
        children: [
          Expanded(
            child: Container(
              height: buttonHeight,
              decoration: BoxDecoration(
                border: Border.all(
                  color: ElegantLightTheme.textTertiary.withValues(alpha:0.3),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Get.back(),
                  borderRadius: BorderRadius.circular(12),
                  child: Center(
                    child: Text(
                      'Cancelar',
                      style: TextStyle(
                        color: ElegantLightTheme.textSecondary,
                        fontSize: fontSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: padding),
          Expanded(
            flex: 2,
            child: Container(
              height: buttonHeight,
              decoration: BoxDecoration(
                gradient: controller.canSave
                    ? ElegantLightTheme.successGradient
                    : null,
                color: controller.canSave
                    ? null
                    : ElegantLightTheme.textTertiary.withValues(alpha:0.3),
                borderRadius: BorderRadius.circular(12),
                boxShadow: controller.canSave
                    ? [
                        BoxShadow(
                          color: ElegantLightTheme.successGradient.colors.first
                              .withValues(alpha:0.4),
                          offset: const Offset(0, 4),
                          blurRadius: 12,
                        ),
                      ]
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: controller.canSave ? controller.save : null,
                  borderRadius: BorderRadius.circular(12),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          controller.isEditMode ? Icons.update : Icons.check,
                          color: Colors.white,
                          size: fontSize + 4,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          controller.isEditMode ? 'Actualizar' : 'Crear Nota de Crédito',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: fontSize,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  void _selectDate() async {
    final selectedDate = await showDatePicker(
      context: Get.context!,
      initialDate: controller.date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: ElegantLightTheme.primaryGradient.colors.first,
              onPrimary: Colors.white,
              surface: ElegantLightTheme.surfaceColor,
              onSurface: ElegantLightTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null) {
      controller.setDate(selectedDate);
    }
  }

  void _addItem() async {
    // Verificar si hay cantidades disponibles
    if (controller.hasAvailableQuantities && !controller.canCreatePartialCreditNote) {
      Get.snackbar(
        'Sin disponibilidad',
        'No hay cantidades disponibles para crear notas de crédito. Todos los productos ya han sido acreditados.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
      return;
    }

    final result = await Get.dialog<Map<String, dynamic>>(
      CreditNoteItemDialog(
        invoiceItems: controller.invoice?.items,
        availableItems: controller.availableItems,
      ),
    );

    if (result != null && result['item'] != null) {
      controller.addItem(result['item']);
    }
  }

  void _editItem(int index) async {
    final item = controller.items[index];
    final result = await Get.dialog<Map<String, dynamic>>(
      CreditNoteItemDialog(
        item: item,
        index: index,
        invoiceItems: controller.invoice?.items,
        availableItems: controller.availableItems,
      ),
    );

    if (result != null && result['item'] != null && result['index'] != null) {
      controller.updateItem(result['index'], result['item']);
    }
  }
}
