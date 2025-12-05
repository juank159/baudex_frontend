// lib/features/inventory/presentation/widgets/futuristic_transfers_list_widget.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/core/theme/futuristic_notifications.dart';
import '../../../../app/core/utils/formatters.dart';
import '../controllers/inventory_transfers_controller.dart';

class FuturisticTransfersListWidget
    extends GetView<InventoryTransfersController> {
  const FuturisticTransfersListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final transfers = controller.filteredTransfers;

      if (transfers.isEmpty) {
        return _buildNoResultsState();
      }

      return Column(
        children:
            transfers.asMap().entries.map((entry) {
              final index = entry.key;
              final transfer = entry.value;

              return TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 300 + (index * 100)),
                curve: ElegantLightTheme.elasticCurve,
                builder: (context, animationValue, child) {
                  final safeOpacity = animationValue.clamp(0.0, 1.0);
                  return Transform.translate(
                    offset: Offset(50 * (1 - safeOpacity), 0),
                    child: Opacity(
                      opacity: safeOpacity,
                      child: _buildTransferCard(transfer),
                    ),
                  );
                },
              );
            }).toList(),
      );
    });
  }

  Widget _buildNoResultsState() {
    return FuturisticContainer(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.warningGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.search_off, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 16),
          const Text(
            'Sin resultados',
            style: TextStyle(
              color: ElegantLightTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No se encontraron transferencias con los filtros aplicados',
            style: TextStyle(
              color: ElegantLightTheme.textSecondary,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FuturisticButton(
            text: 'Limpiar Filtros',
            icon: Icons.clear,
            gradient: ElegantLightTheme.infoGradient,
            onPressed: controller.clearFilters,
          ),
        ],
      ),
    );
  }

  Widget _buildTransferCard(dynamic transfer) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isMobile = screenWidth < 600;
        final isTablet = screenWidth >= 600 && screenWidth < 1200;

        // Responsive values - más compacto
        final cardMargin =
            isMobile
                ? 8.0
                : isTablet
                ? 10.0
                : 12.0;
        final iconSize =
            isMobile
                ? 16.0
                : isTablet
                ? 18.0
                : 20.0;
        final titleFontSize =
            isMobile
                ? 14.0
                : isTablet
                ? 15.0
                : 16.0;
        final subtitleFontSize =
            isMobile
                ? 11.0
                : isTablet
                ? 12.0
                : 13.0;
        final spacing =
            isMobile
                ? 8.0
                : isTablet
                ? 10.0
                : 12.0;
        final iconPadding =
            isMobile
                ? 8.0
                : isTablet
                ? 9.0
                : 10.0;

        return Container(
          margin: EdgeInsets.only(bottom: cardMargin),
          child: FuturisticContainer(
            onTap: () => _showTransferDetails(transfer),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with status and date
                isMobile
                    ? _buildMobileHeader(
                      transfer,
                      iconSize,
                      titleFontSize,
                      subtitleFontSize,
                      iconPadding,
                    )
                    : _buildDesktopHeader(
                      transfer,
                      iconSize,
                      titleFontSize,
                      subtitleFontSize,
                      iconPadding,
                      spacing,
                    ),
                SizedBox(height: spacing),

                // Transfer details - responsive layout
                _buildTransferDetails(transfer, isMobile, isTablet, spacing),

                SizedBox(height: spacing),

                // Action buttons - responsive
                _buildActionButtons(transfer, isMobile, isTablet),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileHeader(
    dynamic transfer,
    double iconSize,
    double titleFontSize,
    double subtitleFontSize,
    double iconPadding,
  ) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(iconPadding),
          decoration: BoxDecoration(
            gradient: _getStatusGradient(transfer['status']),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: _getStatusGradient(
                  transfer['status'],
                ).colors.first.withOpacity(0.3),
                offset: const Offset(0, 2),
                blurRadius: 6,
              ),
            ],
          ),
          child: Icon(
            _getStatusIcon(transfer['status']),
            color: Colors.white,
            size: iconSize,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Transferencia #${transfer['id']}',
                style: TextStyle(
                  color: ElegantLightTheme.textPrimary,
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 1),
              Text(
                _formatDate(DateTime.parse(transfer['createdAt'])),
                style: TextStyle(
                  color: ElegantLightTheme.textSecondary,
                  fontSize: subtitleFontSize,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _buildStatusChip(transfer['status']),
      ],
    );
  }

  Widget _buildDesktopHeader(
    dynamic transfer,
    double iconSize,
    double titleFontSize,
    double subtitleFontSize,
    double iconPadding,
    double spacing,
  ) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(iconPadding),
          decoration: BoxDecoration(
            gradient: _getStatusGradient(transfer['status']),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: _getStatusGradient(
                  transfer['status'],
                ).colors.first.withOpacity(0.3),
                offset: const Offset(0, 4),
                blurRadius: 8,
              ),
            ],
          ),
          child: Icon(
            _getStatusIcon(transfer['status']),
            color: Colors.white,
            size: iconSize,
          ),
        ),
        SizedBox(width: spacing),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Transferencia #${transfer['id']}',
                style: TextStyle(
                  color: ElegantLightTheme.textPrimary,
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
              ),
              const SizedBox(height: 4),
              Text(
                _formatDate(DateTime.parse(transfer['createdAt'])),
                style: TextStyle(
                  color: ElegantLightTheme.textSecondary,
                  fontSize: subtitleFontSize,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
              ),
            ],
          ),
        ),
        _buildStatusChip(transfer['status']),
      ],
    );
  }

  Widget _buildTransferDetails(
    dynamic transfer,
    bool isMobile,
    bool isTablet,
    double spacing,
  ) {
    final detailPadding =
        isMobile
            ? 10.0
            : isTablet
            ? 12.0
            : 14.0;
    final arrowIconSize =
        isMobile
            ? 12.0
            : isTablet
            ? 14.0
            : 16.0;
    final arrowPadding =
        isMobile
            ? 5.0
            : isTablet
            ? 6.0
            : 7.0;
    final horizontalSpacing =
        isMobile
            ? 8.0
            : isTablet
            ? 10.0
            : 12.0;

    return Container(
      padding: EdgeInsets.all(detailPadding),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.glassGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ElegantLightTheme.textSecondary.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          // Warehouse flow - responsive layout
          isMobile
              ? _buildMobileWarehouseFlow(transfer, arrowIconSize, arrowPadding)
              : _buildDesktopWarehouseFlow(
                transfer,
                arrowIconSize,
                arrowPadding,
                horizontalSpacing,
              ),
          SizedBox(height: spacing),

          // Product and quantity info - responsive
          isMobile
              ? _buildMobileProductInfo(transfer)
              : _buildDesktopProductInfo(transfer, horizontalSpacing),

          if (transfer['notes'] != null &&
              transfer['notes'].isNotEmpty &&
              !transfer['notes'].toString().toLowerCase().contains(
                'transfer',
              ) &&
              !transfer['notes'].toString().toLowerCase().contains(
                'transferencia',
              )) ...[
            SizedBox(height: spacing),
            _buildNotesSection(transfer, isMobile),
          ],
        ],
      ),
    );
  }

  Widget _buildMobileWarehouseFlow(
    dynamic transfer,
    double arrowIconSize,
    double arrowPadding,
  ) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: _buildWarehouseInfo(
            'Origen',
            transfer['fromWarehouse'],
            ElegantLightTheme.infoGradient.colors.first,
            Icons.warehouse,
          ),
        ),
        SizedBox(
          width: 44,
          child: Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.primaryGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: ElegantLightTheme.primaryGradient.colors.first
                      .withOpacity(0.3),
                  offset: const Offset(0, 2),
                  blurRadius: 6,
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_forward,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: _buildWarehouseInfo(
            'Destino',
            transfer['toWarehouse'],
            ElegantLightTheme.successGradient.colors.first,
            Icons.warehouse,
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopWarehouseFlow(
    dynamic transfer,
    double arrowIconSize,
    double arrowPadding,
    double horizontalSpacing,
  ) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: _buildWarehouseInfo(
            'Origen',
            transfer['fromWarehouse'],
            ElegantLightTheme.infoGradient.colors.first,
            Icons.warehouse,
          ),
        ),
        SizedBox(
          width: 100,
          child: Center(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: horizontalSpacing),
              padding: EdgeInsets.all(arrowPadding),
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.arrow_forward,
                color: Colors.white,
                size: arrowIconSize,
              ),
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: _buildWarehouseInfo(
            'Destino',
            transfer['toWarehouse'],
            ElegantLightTheme.successGradient.colors.first,
            Icons.warehouse,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileProductInfo(dynamic transfer) {
    final isPending = transfer['status'] == 'pending';

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: _buildInfoItem(
            'Productos',
            '${transfer['totalProducts']}',
            Icons.inventory_2,
            ElegantLightTheme.warningGradient.colors.first,
          ),
        ),

        // Centro: Botón Ver Detalles (solo icono en mobile) para non-pending o espacio vacío para pending
        SizedBox(
          width: 44,
          child:
              !isPending
                  ? Center(
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: ElegantLightTheme.infoGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: ElegantLightTheme.infoGradient.colors.first
                                .withOpacity(0.3),
                            offset: const Offset(0, 2),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _showTransferDetails(transfer),
                          borderRadius: BorderRadius.circular(12),
                          child: const Icon(
                            Icons.visibility,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  )
                  : Container(), // Espacio vacío para transfers pending
        ),

        Expanded(
          flex: 2,
          child: _buildInfoItem(
            'Cantidad Total',
            AppFormatters.formatNumber(transfer['totalQuantity']),
            Icons.format_list_numbered,
            ElegantLightTheme.infoGradient.colors.first,
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopProductInfo(dynamic transfer, double horizontalSpacing) {
    final isPending = transfer['status'] == 'pending';

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: _buildInfoItem(
            'Productos',
            '${transfer['totalProducts']}',
            Icons.inventory_2,
            ElegantLightTheme.warningGradient.colors.first,
          ),
        ),

        // Centro: Botón Ver Detalles para non-pending o espacio vacío para pending
        SizedBox(
          width: 100,
          child:
              !isPending
                  ? Center(
                    child: Container(
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        gradient: ElegantLightTheme.infoGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: ElegantLightTheme.infoGradient.colors.first
                                .withOpacity(0.3),
                            offset: const Offset(0, 2),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _showTransferDetails(transfer),
                          borderRadius: BorderRadius.circular(12),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.visibility,
                                color: Colors.white,
                                size: 14,
                              ),
                              SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Ver',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                  : Container(), // Espacio vacío para transfers pending
        ),

        Expanded(
          flex: 3,
          child: _buildInfoItem(
            'Cantidad Total',
            AppFormatters.formatNumber(transfer['totalQuantity']),
            Icons.format_list_numbered,
            ElegantLightTheme.infoGradient.colors.first,
          ),
        ),
      ],
    );
  }

  Widget _buildNotesSection(dynamic transfer, bool isMobile) {
    final notesPadding = isMobile ? 10.0 : 12.0;
    final notesFontSize = isMobile ? 11.0 : 12.0;
    final notesIconSize = isMobile ? 14.0 : 16.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(notesPadding),
      decoration: BoxDecoration(
        color: ElegantLightTheme.primaryBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: ElegantLightTheme.primaryBlue.withOpacity(0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.notes,
            color: ElegantLightTheme.primaryBlue,
            size: notesIconSize,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              transfer['notes'],
              style: TextStyle(
                color: ElegantLightTheme.textSecondary,
                fontSize: notesFontSize,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(dynamic transfer, bool isMobile, bool isTablet) {
    final buttonHeight =
        isMobile
            ? 32.0
            : isTablet
            ? 34.0
            : 36.0;
    final buttonSpacing =
        isMobile
            ? 6.0
            : isTablet
            ? 8.0
            : 10.0;

    if (transfer['status'] == 'pending') {
      return isMobile
          ? Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: FuturisticButton(
                  text: 'Confirmar',
                  icon: Icons.check,
                  gradient: ElegantLightTheme.successGradient,
                  height: buttonHeight,
                  onPressed: () => _confirmTransfer(transfer),
                ),
              ),
              SizedBox(height: buttonSpacing),
              SizedBox(
                width: double.infinity,
                child: FuturisticButton(
                  text: 'Cancelar',
                  icon: Icons.cancel,
                  gradient: ElegantLightTheme.errorGradient,
                  height: buttonHeight,
                  onPressed: () => _cancelTransfer(transfer),
                ),
              ),
            ],
          )
          : Row(
            children: [
              Expanded(
                child: FuturisticButton(
                  text: 'Confirmar',
                  icon: Icons.check,
                  gradient: ElegantLightTheme.successGradient,
                  height: buttonHeight,
                  onPressed: () => _confirmTransfer(transfer),
                ),
              ),
              SizedBox(width: buttonSpacing),
              Expanded(
                child: FuturisticButton(
                  text: 'Cancelar',
                  icon: Icons.cancel,
                  gradient: ElegantLightTheme.errorGradient,
                  height: buttonHeight,
                  onPressed: () => _cancelTransfer(transfer),
                ),
              ),
            ],
          );
    } else {
      // Para estados no pending, el botón "Ver Detalles" está integrado en la sección de productos
      // No necesitamos mostrar botones adicionales aquí
      return const SizedBox.shrink();
    }
  }

  Widget _buildWarehouseInfo(
    String label,
    Map<String, dynamic> warehouse,
    Color color,
    IconData icon,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 200;
        final iconPadding = isMobile ? 5.0 : 6.0;
        final iconSize = isMobile ? 14.0 : 16.0;
        final labelFontSize = isMobile ? 9.0 : 10.0;
        final nameFontSize = isMobile ? 11.0 : 12.0;
        final codeFontSize = isMobile ? 9.0 : 10.0;
        final spacing = isMobile ? 3.0 : 4.0;

        return Column(
          children: [
            Container(
              padding: EdgeInsets.all(iconPadding),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: iconSize),
            ),
            SizedBox(height: spacing),
            Text(
              label,
              style: TextStyle(
                color: ElegantLightTheme.textTertiary,
                fontSize: labelFontSize,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 1),
            Text(
              warehouse['name'] ?? 'Sin nombre',
              style: TextStyle(
                color: ElegantLightTheme.textPrimary,
                fontSize: nameFontSize,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              softWrap: true,
            ),
            if (warehouse['code'] != null)
              Text(
                warehouse['code'],
                style: TextStyle(
                  color: ElegantLightTheme.textSecondary,
                  fontSize: codeFontSize,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
              ),
          ],
        );
      },
    );
  }

  Widget _buildInfoItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 200;
        final iconSize = isMobile ? 16.0 : 18.0;
        final labelFontSize = isMobile ? 9.0 : 10.0;
        final valueFontSize = isMobile ? 11.0 : 12.0;
        final spacing = isMobile ? 2.0 : 3.0;

        return Column(
          children: [
            Icon(icon, color: color, size: iconSize),
            SizedBox(height: spacing),
            Text(
              label,
              style: TextStyle(
                color: ElegantLightTheme.textTertiary,
                fontSize: labelFontSize,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 1),
            Text(
              value,
              style: TextStyle(
                color: ElegantLightTheme.textPrimary,
                fontSize: valueFontSize,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: isMobile ? 2 : 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = MediaQuery.of(context).size.width < 600;
        final horizontalPadding = isMobile ? 6.0 : 10.0;
        final verticalPadding = isMobile ? 3.0 : 4.0;
        final iconSize = isMobile ? 10.0 : 12.0;
        final fontSize = isMobile ? 9.0 : 11.0;
        final spacing = isMobile ? 3.0 : 4.0;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          decoration: BoxDecoration(
            gradient: _getStatusGradient(status),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _getStatusGradient(status).colors.first.withOpacity(0.3),
                offset: const Offset(0, 2),
                blurRadius: 6,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_getStatusIcon(status), color: Colors.white, size: iconSize),
              SizedBox(width: spacing),
              Text(
                _getStatusText(status),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  LinearGradient _getStatusGradient(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return ElegantLightTheme.warningGradient;
      case 'confirmed':
        return ElegantLightTheme.successGradient;
      case 'cancelled':
        return ElegantLightTheme.errorGradient;
      default:
        return ElegantLightTheme.infoGradient;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.schedule;
      case 'confirmed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pendiente';
      case 'confirmed':
        return 'Confirmada';
      case 'cancelled':
        return 'Cancelada';
      default:
        return status;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _confirmTransfer(dynamic transfer) {
    FuturisticNotifications.showProcessing(
      'Confirmando Transferencia',
      'Procesando la confirmación de la transferencia...',
    );

    // Simulate API call
    Future.delayed(const Duration(seconds: 2), () {
      FuturisticNotifications.showSuccess(
        '¡Transferencia Confirmada!',
        'La transferencia ha sido procesada exitosamente',
      );
      // TODO: Update transfer status in controller
      controller.refreshTransfers();
    });
  }

  void _cancelTransfer(dynamic transfer) {
    Get.dialog(
      FuturisticContainer(
        margin: const EdgeInsets.all(60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.warningGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.warning, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 16),
            const Text(
              'Cancelar Transferencia',
              style: TextStyle(
                color: ElegantLightTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '¿Está seguro de que desea cancelar esta transferencia? Esta acción no se puede deshacer.',
              style: TextStyle(
                color: ElegantLightTheme.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: FuturisticButton(
                    text: 'No, Mantener',
                    onPressed: () => Get.back(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FuturisticButton(
                    text: 'Sí, Cancelar',
                    gradient: ElegantLightTheme.errorGradient,
                    onPressed: () {
                      Get.back();
                      FuturisticNotifications.showProcessing(
                        'Cancelando Transferencia',
                        'Procesando la cancelación...',
                      );

                      // Simulate API call
                      Future.delayed(const Duration(seconds: 1), () {
                        FuturisticNotifications.showSuccess(
                          'Transferencia Cancelada',
                          'La transferencia ha sido cancelada',
                        );
                        // TODO: Update transfer status in controller
                        controller.refreshTransfers();
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showTransferDetails(dynamic transfer) {
    Get.dialog(
      LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final screenHeight = constraints.maxHeight;
          final isMobile = screenWidth < 600;
          final isTablet = screenWidth >= 600 && screenWidth < 1200;

          // Responsive dialog sizing
          final dialogWidth =
              isMobile
                  ? screenWidth * 0.9
                  : isTablet
                  ? screenWidth * 0.7
                  : screenWidth * 0.5;
          final maxDialogHeight = screenHeight * 0.8;

          final padding = isMobile ? 16.0 : 24.0;
          final iconSize = isMobile ? 20.0 : 24.0;
          final titleFontSize = isMobile ? 18.0 : 22.0;
          final statusFontSize = isMobile ? 12.0 : 14.0;
          final spacing = isMobile ? 16.0 : 20.0;

          return Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: dialogWidth,
                constraints: BoxConstraints(maxHeight: maxDialogHeight),
                margin: EdgeInsets.symmetric(
                  horizontal: isMobile ? 20 : 40,
                  vertical: 40,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.white, Colors.white.withOpacity(0.95)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      offset: const Offset(0, 10),
                      blurRadius: 30,
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: ElegantLightTheme.primaryBlue.withOpacity(0.1),
                      offset: const Offset(0, 0),
                      blurRadius: 20,
                      spreadRadius: 0,
                    ),
                  ],
                  border: Border.all(
                    color: ElegantLightTheme.primaryBlue.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(padding),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header moderno con gradiente
                        Container(
                          padding: EdgeInsets.all(spacing),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                _getStatusGradient(
                                  transfer['status'],
                                ).colors.first.withOpacity(0.1),
                                _getStatusGradient(
                                  transfer['status'],
                                ).colors.last.withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _getStatusGradient(
                                transfer['status'],
                              ).colors.first.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(padding * 0.75),
                                decoration: BoxDecoration(
                                  gradient: _getStatusGradient(
                                    transfer['status'],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _getStatusGradient(
                                        transfer['status'],
                                      ).colors.first.withOpacity(0.4),
                                      offset: const Offset(0, 4),
                                      blurRadius: 12,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  _getStatusIcon(transfer['status']),
                                  color: Colors.white,
                                  size: iconSize,
                                ),
                              ),
                              SizedBox(width: spacing),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Transferencia #${transfer['id']}',
                                      style: TextStyle(
                                        color: ElegantLightTheme.textPrimary,
                                        fontSize: titleFontSize,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: _getStatusGradient(
                                          transfer['status'],
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: _getStatusGradient(
                                              transfer['status'],
                                            ).colors.first.withOpacity(0.3),
                                            offset: const Offset(0, 2),
                                            blurRadius: 6,
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        _getStatusText(transfer['status']),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: statusFontSize,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => Get.back(),
                                icon: Icon(
                                  Icons.close,
                                  color: ElegantLightTheme.textSecondary,
                                  size: iconSize,
                                ),
                                style: IconButton.styleFrom(
                                  backgroundColor: ElegantLightTheme
                                      .textSecondary
                                      .withOpacity(0.1),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: spacing),

                        // Información detallada en cards elegantes
                        _buildDetailCard(
                          'Información General',
                          [
                            _buildDetailRow(
                              'Fecha de Creación',
                              _formatDate(
                                DateTime.parse(transfer['createdAt']),
                              ),
                            ),
                            _buildDetailRow(
                              'Almacén de Origen',
                              transfer['fromWarehouse']['name'],
                            ),
                            _buildDetailRow(
                              'Almacén de Destino',
                              transfer['toWarehouse']['name'],
                            ),
                          ],
                          Icons.info_outline,
                          ElegantLightTheme.infoGradient,
                          isMobile,
                        ),

                        SizedBox(height: spacing * 0.75),

                        _buildProductsDetailCard(transfer, isMobile, spacing),

                        if (transfer['notes'] != null &&
                            transfer['notes'].isNotEmpty) ...[
                          SizedBox(height: spacing * 0.75),
                          _buildDetailCard(
                            'Notas Adicionales',
                            [
                              _buildDetailRow(
                                'Observaciones',
                                transfer['notes'],
                              ),
                            ],
                            Icons.notes,
                            ElegantLightTheme.successGradient,
                            isMobile,
                          ),
                        ],

                        SizedBox(height: spacing * 1.5),

                        // Botones de acción modernos
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: ElegantLightTheme.primaryGradient,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: ElegantLightTheme.primaryBlue
                                          .withOpacity(0.3),
                                      offset: const Offset(0, 4),
                                      blurRadius: 12,
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => Get.back(),
                                    borderRadius: BorderRadius.circular(16),
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: isMobile ? 12 : 16,
                                        horizontal: 24,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.check_circle,
                                            color: Colors.white,
                                            size: isMobile ? 18 : 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Entendido',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: isMobile ? 14 : 16,
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
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: TextStyle(
              color: ElegantLightTheme.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: ElegantLightTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            softWrap: true,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailCard(
    String title,
    List<Widget> details,
    IconData icon,
    LinearGradient gradient,
    bool isMobile,
  ) {
    final padding = isMobile ? 16.0 : 20.0;
    final iconSize = isMobile ? 18.0 : 20.0;
    final titleFontSize = isMobile ? 14.0 : 16.0;
    final spacing = isMobile ? 12.0 : 16.0;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            gradient.colors.first.withOpacity(0.05),
            gradient.colors.last.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: gradient.colors.first.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.1),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 8 : 10),
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: gradient.colors.first.withOpacity(0.3),
                      offset: const Offset(0, 2),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: iconSize),
              ),
              SizedBox(width: spacing * 0.75),
              Text(
                title,
                style: TextStyle(
                  color: ElegantLightTheme.textPrimary,
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: spacing),
          ...details.map(
            (detail) => Padding(
              padding: EdgeInsets.only(bottom: spacing * 0.75),
              child: detail,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsDetailCard(
    dynamic transfer,
    bool isMobile,
    double spacing,
  ) {
    final productDetails = transfer['productDetails'] as List<dynamic>;
    final totalProducts = transfer['totalProducts'] as int;
    final totalQuantity = transfer['totalQuantity'] as int;

    // Si es un solo producto, mostrar formato simple
    if (totalProducts == 1) {
      final product = productDetails.first;
      return _buildDetailCard(
        'Detalles del Producto',
        [
          _buildDetailRow('Producto', product['name']),
          _buildDetailRow('SKU', product['sku']),
          _buildDetailRow(
            'Cantidad',
            AppFormatters.formatNumber(product['quantity']),
          ),
        ],
        Icons.inventory_2,
        ElegantLightTheme.warningGradient,
        isMobile,
      );
    }

    // Si son múltiples productos, mostrar lista expandida
    return _buildDetailCard(
      'Productos Transferidos ($totalProducts)',
      [
        _buildDetailRow('Total de Productos', totalProducts.toString()),
        _buildDetailRow(
          'Cantidad Total',
          AppFormatters.formatNumber(totalQuantity),
        ),
        const Divider(height: 20),
        ...productDetails.asMap().entries.map((entry) {
          final index = entry.key;
          final product = entry.value;
          return Padding(
            padding: EdgeInsets.only(
              bottom: index < productDetails.length - 1 ? 12 : 0,
            ),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${index + 1}. ${product['name']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'SKU: ${product['sku']}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'Cantidad: ${AppFormatters.formatNumber(product['quantity'])}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: ElegantLightTheme.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
      Icons.inventory_2,
      ElegantLightTheme.warningGradient,
      isMobile,
    );
  }
}
