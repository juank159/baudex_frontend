// lib/features/credit_notes/presentation/screens/credit_note_list_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../../app/core/utils/responsive_helper.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../../../../app/shared/widgets/app_drawer.dart';
import '../../domain/entities/credit_note.dart';
import '../controllers/credit_note_list_controller.dart';

class CreditNoteListScreen extends GetView<CreditNoteListController> {
  const CreditNoteListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ElegantLightTheme.backgroundColor,
      appBar: _buildAppBar(context),
      drawer: const AppDrawer(currentRoute: '/credit-notes'),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [ElegantLightTheme.backgroundColor, ElegantLightTheme.cardColor],
          ),
        ),
        child: ResponsiveHelper.responsive(
          context,
          mobile: _buildMobileLayout(context),
          tablet: _buildTabletLayout(context),
          desktop: _buildDesktopLayout(context),
        ),
      ),
      floatingActionButton: _buildFAB(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final isSmall = ResponsiveHelper.isMobile(context);
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      toolbarHeight: isSmall ? 50 : 56,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: ElegantLightTheme.primaryGradient,
          boxShadow: ElegantLightTheme.elevatedShadow,
        ),
      ),
      // El icono del drawer se muestra automáticamente
      iconTheme: const IconThemeData(color: Colors.white),
      title: Text(
        'Notas de Crédito',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: isSmall ? 16 : 18,
          color: Colors.white,
        ),
      ),
      actions: [
        Obx(() => IconButton(
              icon: controller.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Icon(Icons.refresh, color: Colors.white, size: isSmall ? 20 : 22),
              onPressed: controller.isLoading ? null : controller.refreshCreditNotes,
              tooltip: 'Actualizar',
            )),
        if (!ResponsiveHelper.isDesktop(context))
          IconButton(
            icon: Icon(Icons.filter_list, color: Colors.white, size: isSmall ? 20 : 22),
            onPressed: () => _showFilters(context),
            tooltip: 'Filtros',
          ),
        SizedBox(width: isSmall ? 4 : 8),
      ],
    );
  }

  // ==================== LAYOUTS ====================

  Widget _buildDesktopLayout(BuildContext context) {
    return Obx(() {
      if (controller.isLoading && controller.creditNotes.isEmpty) {
        return const LoadingWidget(message: 'Cargando notas de crédito...');
      }

      return Row(
        children: [
          _DesktopSidebar(controller: controller),
          Expanded(
            child: Column(
              children: [
                _DesktopToolbar(controller: controller),
                Expanded(child: _buildCreditNotesList(context)),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: _SearchField(controller: controller),
        ),
        _buildFilterChips(context),
        Expanded(child: _buildCreditNotesList(context)),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: _SearchField(controller: controller),
        ),
        _buildFilterChips(context),
        Expanded(child: _buildCreditNotesList(context)),
      ],
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    return Obx(() {
      if (!controller.hasFilters) return const SizedBox.shrink();
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        margin: const EdgeInsets.only(bottom: 8),
        child: Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            if (controller.selectedStatus != null)
              _buildFilterChip(
                controller.selectedStatus!.displayName,
                _getStatusColor(controller.selectedStatus!),
                () => controller.setStatusFilter(null),
              ),
            if (controller.selectedType != null)
              _buildFilterChip(
                controller.selectedType!.displayName,
                controller.selectedType == CreditNoteType.full ? Colors.purple : Colors.teal,
                () => controller.setTypeFilter(null),
              ),
            _buildFilterChip('Limpiar', Colors.grey, controller.clearFilters),
          ],
        ),
      );
    });
  }

  Widget _buildFilterChip(String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 11)),
            const SizedBox(width: 4),
            Icon(Icons.close, size: 12, color: color),
          ],
        ),
      ),
    );
  }

  // ==================== LISTA ====================

  Widget _buildCreditNotesList(BuildContext context) {
    return Obx(() {
      if (controller.isLoading && controller.creditNotes.isEmpty) {
        return const LoadingWidget(message: 'Cargando...');
      }

      if (controller.isEmpty) {
        return _buildEmptyState(context);
      }

      return RefreshIndicator(
        onRefresh: controller.refreshCreditNotes,
        color: ElegantLightTheme.primaryBlue,
        child: ListView.builder(
          controller: controller.scrollController,
          padding: const EdgeInsets.all(12),
          itemCount: controller.creditNotes.length + (controller.hasNextPage ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == controller.creditNotes.length) {
              return _buildLoadingMore();
            }
            return _buildCreditNoteCard(context, controller.creditNotes[index]);
          },
        ),
      );
    });
  }

  Widget _buildCreditNoteCard(BuildContext context, CreditNote creditNote) {
    final isDesktop = ResponsiveHelper.isDesktop(context);

    if (isDesktop) {
      return _buildDesktopCard(context, creditNote);
    }
    // Tablet y móvil usan el mismo card compacto
    return _buildCompactCard(context, creditNote);
  }

  // Card para Desktop - Layout horizontal moderno
  Widget _buildDesktopCard(BuildContext context, CreditNote creditNote) {
    final statusColor = _getStatusColor(creditNote.status);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallDesktop = screenWidth < 1200;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => controller.goToDetail(creditNote.id),
          borderRadius: BorderRadius.circular(16),
          hoverColor: ElegantLightTheme.primaryBlue.withValues(alpha: 0.02),
          child: Padding(
            padding: EdgeInsets.all(isSmallDesktop ? 14 : 18),
            child: Row(
              children: [
                // === ICONO ===
                Container(
                  width: isSmallDesktop ? 44 : 50,
                  height: isSmallDesktop ? 44 : 50,
                  decoration: BoxDecoration(
                    gradient: _getStatusGradient(creditNote.status),
                    borderRadius: BorderRadius.circular(isSmallDesktop ? 12 : 14),
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(Icons.receipt_long, color: Colors.white, size: isSmallDesktop ? 20 : 24),
                  ),
                ),
                SizedBox(width: isSmallDesktop ? 12 : 16),

                // === INFO PRINCIPAL ===
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              creditNote.number,
                              style: TextStyle(
                                fontSize: isSmallDesktop ? 13 : 15,
                                fontWeight: FontWeight.w700,
                                color: ElegantLightTheme.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildStatusBadge(creditNote.status),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.person_outline, size: isSmallDesktop ? 12 : 14, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              creditNote.customerName,
                              style: TextStyle(fontSize: isSmallDesktop ? 11 : 13, color: Colors.grey.shade600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // === FACTURA ASOCIADA ===
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.receipt_outlined, size: isSmallDesktop ? 12 : 14, color: ElegantLightTheme.primaryBlue),
                    const SizedBox(width: 4),
                    Text(
                      isSmallDesktop ? _shortenInvoice(creditNote.invoiceNumber) : creditNote.invoiceNumber,
                      style: TextStyle(
                        fontSize: isSmallDesktop ? 10 : 12,
                        fontWeight: FontWeight.w500,
                        color: ElegantLightTheme.primaryBlue,
                      ),
                    ),
                  ],
                ),
                SizedBox(width: isSmallDesktop ? 10 : 16),

                // === RAZÓN ===
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(creditNote.reasonIcon, size: isSmallDesktop ? 12 : 14, color: _getReasonColor(creditNote.reason)),
                    const SizedBox(width: 4),
                    Text(
                      isSmallDesktop ? _shortenReason(creditNote.reason) : creditNote.reasonDisplayName,
                      style: TextStyle(
                        fontSize: isSmallDesktop ? 10 : 12,
                        fontWeight: FontWeight.w500,
                        color: _getReasonColor(creditNote.reason),
                      ),
                    ),
                  ],
                ),
                SizedBox(width: isSmallDesktop ? 10 : 16),

                // === FECHA ===
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today, size: isSmallDesktop ? 12 : 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      _formatDateShort(creditNote.date),
                      style: TextStyle(fontSize: isSmallDesktop ? 10 : 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                SizedBox(width: isSmallDesktop ? 10 : 16),

                // === TOTAL ===
                Container(
                  padding: EdgeInsets.symmetric(horizontal: isSmallDesktop ? 10 : 14, vertical: isSmallDesktop ? 6 : 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF10B981).withValues(alpha: 0.15),
                        const Color(0xFF10B981).withValues(alpha: 0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    AppFormatters.formatCurrency(creditNote.total),
                    style: TextStyle(
                      fontSize: isSmallDesktop ? 13 : 15,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ),
                SizedBox(width: isSmallDesktop ? 10 : 14),

                // === ACCIONES ===
                _buildDesktopActions(creditNote, isSmallDesktop),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDateShort(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year.toString().substring(2)}';
  }

  Widget _buildStatusBadge(CreditNoteStatus status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status.displayName,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getReasonColor(CreditNoteReason reason) {
    switch (reason) {
      case CreditNoteReason.returnedGoods:
        return Colors.orange;
      case CreditNoteReason.damagedGoods:
        return Colors.red.shade400;
      case CreditNoteReason.billingError:
        return Colors.amber.shade700;
      case CreditNoteReason.priceAdjustment:
        return Colors.blue;
      case CreditNoteReason.orderCancellation:
        return Colors.red;
      case CreditNoteReason.customerDissatisfaction:
        return Colors.purple;
      case CreditNoteReason.inventoryAdjustment:
        return Colors.teal;
      case CreditNoteReason.discountGranted:
        return Colors.green;
      case CreditNoteReason.other:
        return Colors.grey;
    }
  }

  Widget _buildDesktopActions(CreditNote creditNote, bool isSmall) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (creditNote.canBeConfirmed)
          _buildActionButton(
            Icons.check,
            'Confirmar',
            const Color(0xFF059669), // Verde más intenso
            isSmall,
            () => controller.confirmCreditNote(creditNote.id),
          ),
        if (creditNote.canBeCancelled)
          _buildActionButton(
            Icons.close,
            'Cancelar',
            const Color(0xFFEA580C), // Naranja más intenso
            isSmall,
            () => controller.cancelCreditNote(creditNote.id),
          ),
        _buildMoreMenu(creditNote, isSmall),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String tooltip, Color color, bool isSmall, VoidCallback onPressed) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          margin: EdgeInsets.only(left: isSmall ? 4 : 6),
          padding: EdgeInsets.all(isSmall ? 7 : 9),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color, color.withValues(alpha: 0.85)],
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.35),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, size: isSmall ? 16 : 18, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildMoreMenu(CreditNote creditNote, bool isSmall) {
    return PopupMenuButton<String>(
      onSelected: (action) => _handleAction(action, creditNote),
      padding: EdgeInsets.zero,
      offset: const Offset(0, 40),
      icon: Container(
        margin: EdgeInsets.only(left: isSmall ? 4 : 6),
        padding: EdgeInsets.all(isSmall ? 7 : 9),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.more_vert, size: isSmall ? 16 : 18, color: Colors.grey.shade700),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 8,
      itemBuilder: (context) => [
        _buildMenuItem('view', Icons.visibility_outlined, 'Ver Detalle', Colors.grey.shade700),
        _buildMenuItem('pdf', Icons.picture_as_pdf, 'Descargar PDF', Colors.red),
        if (creditNote.canBeDeleted)
          _buildMenuItem('delete', Icons.delete_outline, 'Eliminar', Colors.red),
      ],
    );
  }

  PopupMenuItem<String> _buildMenuItem(String value, IconData icon, String text, Color color) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 12),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // Card compacta para Tablet y Móvil
  Widget _buildCompactCard(BuildContext context, CreditNote creditNote) {
    final statusColor = _getStatusColor(creditNote.status);
    final reasonColor = _getReasonColor(creditNote.reason);
    final isMobile = ResponsiveHelper.isMobile(context);

    // Tamaños adaptativos
    final iconSize = isMobile ? 38.0 : 42.0;
    final iconRadius = isMobile ? 10.0 : 12.0;
    final iconInnerSize = isMobile ? 18.0 : 20.0;
    final numberFontSize = isMobile ? 13.0 : 15.0;
    final dateFontSize = isMobile ? 10.0 : 12.0;
    final infoFontSize = isMobile ? 11.0 : 13.0;
    final reasonFontSize = isMobile ? 10.0 : 12.0;
    final totalFontSize = isMobile ? 12.0 : 14.0;
    final padding = isMobile ? 12.0 : 14.0;
    final spacing = isMobile ? 8.0 : 12.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => controller.goToDetail(creditNote.id),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // === HEADER: Icono + Número + Estado + Menú ===
                Row(
                  children: [
                    // Icono
                    Container(
                      width: iconSize,
                      height: iconSize,
                      decoration: BoxDecoration(
                        gradient: _getStatusGradient(creditNote.status),
                        borderRadius: BorderRadius.circular(iconRadius),
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(Icons.receipt_long, color: Colors.white, size: iconInnerSize),
                      ),
                    ),
                    SizedBox(width: isMobile ? 10 : 12),
                    // Número + Estado + Fecha
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Número y Estado en la misma fila
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  creditNote.number,
                                  style: TextStyle(
                                    fontSize: numberFontSize,
                                    fontWeight: FontWeight.w700,
                                    color: ElegantLightTheme.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(width: isMobile ? 6 : 8),
                              _buildStatusBadgeCompact(creditNote.status, isMobile),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatDate(creditNote.date),
                            style: TextStyle(fontSize: dateFontSize, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                    // Menú
                    _buildCompactMenu(creditNote, isMobile),
                  ],
                ),
                SizedBox(height: spacing),

                // === INFO: Cliente + Factura ===
                Row(
                  children: [
                    Icon(Icons.person_outline, size: isMobile ? 12 : 14, color: Colors.grey.shade500),
                    SizedBox(width: isMobile ? 4 : 6),
                    Expanded(
                      child: Text(
                        creditNote.customerName,
                        style: TextStyle(fontSize: infoFontSize, color: Colors.grey.shade700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: isMobile ? 8 : 12),
                    Icon(Icons.receipt_outlined, size: isMobile ? 12 : 14, color: ElegantLightTheme.primaryBlue),
                    SizedBox(width: isMobile ? 3 : 4),
                    Text(
                      isMobile ? _shortenInvoice(creditNote.invoiceNumber) : creditNote.invoiceNumber,
                      style: TextStyle(
                        fontSize: isMobile ? 10 : 12,
                        fontWeight: FontWeight.w500,
                        color: ElegantLightTheme.primaryBlue,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isMobile ? 8 : 10),

                // === FOOTER: Razón + Total ===
                Row(
                  children: [
                    // Razón
                    Icon(creditNote.reasonIcon, size: isMobile ? 12 : 14, color: reasonColor),
                    SizedBox(width: isMobile ? 4 : 6),
                    Expanded(
                      child: Text(
                        isMobile ? _shortenReason(creditNote.reason) : creditNote.reasonDisplayName,
                        style: TextStyle(
                          fontSize: reasonFontSize,
                          fontWeight: FontWeight.w500,
                          color: reasonColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Total
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 10 : 12,
                        vertical: isMobile ? 5 : 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF10B981).withValues(alpha: 0.15),
                            const Color(0xFF10B981).withValues(alpha: 0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        AppFormatters.formatCurrency(creditNote.total),
                        style: TextStyle(
                          fontSize: totalFontSize,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF10B981),
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
    );
  }

  // Abreviar número de factura: INV-2025-790728 -> INV-790728
  String _shortenInvoice(String invoice) {
    final parts = invoice.split('-');
    if (parts.length >= 3) {
      return '${parts[0]}-${parts.last}';
    }
    return invoice;
  }

  // Abreviar razones para móvil
  String _shortenReason(CreditNoteReason reason) {
    switch (reason) {
      case CreditNoteReason.returnedGoods:
        return 'Devolución';
      case CreditNoteReason.damagedGoods:
        return 'Mercancía Dañada';
      case CreditNoteReason.billingError:
        return 'Error Factura';
      case CreditNoteReason.priceAdjustment:
        return 'Ajuste Precio';
      case CreditNoteReason.orderCancellation:
        return 'Cancelación';
      case CreditNoteReason.customerDissatisfaction:
        return 'Insatisfacción';
      case CreditNoteReason.inventoryAdjustment:
        return 'Ajuste Inv.';
      case CreditNoteReason.discountGranted:
        return 'Descuento';
      case CreditNoteReason.other:
        return 'Otro';
    }
  }

  Widget _buildStatusBadgeCompact(CreditNoteStatus status, bool isMobile) {
    final color = _getStatusColor(status);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 10,
        vertical: isMobile ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isMobile ? 5 : 6,
            height: isMobile ? 5 : 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: isMobile ? 4 : 6),
          Text(
            status.displayName,
            style: TextStyle(
              fontSize: isMobile ? 9 : 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactMenu(CreditNote creditNote, bool isMobile) {
    return PopupMenuButton<String>(
      onSelected: (action) => _handleAction(action, creditNote),
      padding: EdgeInsets.zero,
      offset: const Offset(0, 40),
      icon: Container(
        padding: EdgeInsets.all(isMobile ? 6 : 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.more_vert, size: isMobile ? 16 : 18, color: Colors.grey.shade600),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 8,
      itemBuilder: (context) => [
        _buildMenuItem('view', Icons.visibility_outlined, 'Ver Detalle', Colors.grey.shade700),
        if (creditNote.canBeConfirmed)
          _buildMenuItem('confirm', Icons.check_circle_outline, 'Confirmar', const Color(0xFF10B981)),
        if (creditNote.canBeCancelled)
          _buildMenuItem('cancel', Icons.cancel_outlined, 'Cancelar', Colors.orange),
        _buildMenuItem('pdf', Icons.picture_as_pdf, 'Descargar PDF', Colors.red),
        if (creditNote.canBeDeleted)
          _buildMenuItem('delete', Icons.delete_outline, 'Eliminar', Colors.red),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isSmall = ResponsiveHelper.isMobile(context);
    final hasFilters = controller.hasFilters;

    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: ElegantLightTheme.cardGradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ElegantLightTheme.textTertiary.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasFilters ? Icons.search_off : Icons.receipt_long_outlined,
              size: isSmall ? 48 : 56,
              color: hasFilters ? Colors.orange.withValues(alpha: 0.7) : ElegantLightTheme.primaryBlue.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              hasFilters ? 'Sin resultados' : 'No hay notas de crédito',
              style: TextStyle(fontSize: isSmall ? 16 : 18, fontWeight: FontWeight.w700, color: ElegantLightTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilters
                  ? 'No se encontraron notas con los filtros aplicados'
                  : 'Crea tu primera nota de crédito',
              style: TextStyle(fontSize: isSmall ? 12 : 14, color: ElegantLightTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (hasFilters)
              InkWell(
                onTap: controller.clearFilters,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.clear_all, color: Colors.orange, size: 18),
                      SizedBox(width: 8),
                      Text('Limpiar Filtros', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w700, fontSize: 14)),
                    ],
                  ),
                ),
              )
            else
              InkWell(
                onTap: () => controller.goToCreate(),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text('Crear Nota', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingMore() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
    );
  }

  Widget _buildFAB(BuildContext context) {
    if (ResponsiveHelper.isDesktop(context)) return const SizedBox.shrink();

    final isSmall = ResponsiveHelper.isMobile(context);
    return Container(
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.primaryGradient,
        borderRadius: BorderRadius.circular(isSmall ? 14 : 16),
        boxShadow: [
          BoxShadow(color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => controller.goToCreate(),
          borderRadius: BorderRadius.circular(isSmall ? 14 : 16),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isSmall ? 16 : 20, vertical: isSmall ? 12 : 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, color: Colors.white, size: isSmall ? 20 : 22),
                if (!isSmall) ...[
                  const SizedBox(width: 8),
                  const Text('Nueva Nota', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleAction(String action, CreditNote creditNote) {
    switch (action) {
      case 'view':
        controller.goToDetail(creditNote.id);
        break;
      case 'confirm':
        controller.confirmCreditNote(creditNote.id);
        break;
      case 'cancel':
        controller.cancelCreditNote(creditNote.id);
        break;
      case 'delete':
        controller.deleteCreditNote(creditNote.id);
        break;
      case 'pdf':
        controller.downloadPdf(creditNote.id);
        break;
    }
  }

  void _showFilters(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FiltersBottomSheet(controller: controller),
    );
  }

  // Helpers
  Color _getStatusColor(CreditNoteStatus status) {
    switch (status) {
      case CreditNoteStatus.draft:
        return Colors.grey;
      case CreditNoteStatus.confirmed:
        return const Color(0xFF10B981);
      case CreditNoteStatus.cancelled:
        return Colors.red;
    }
  }

  LinearGradient _getStatusGradient(CreditNoteStatus status) {
    switch (status) {
      case CreditNoteStatus.draft:
        return LinearGradient(colors: [Colors.grey.shade600, Colors.grey.shade400]);
      case CreditNoteStatus.confirmed:
        return ElegantLightTheme.successGradient;
      case CreditNoteStatus.cancelled:
        return ElegantLightTheme.errorGradient;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

// ==================== WIDGETS EXTRAÍDOS ====================

class _DesktopSidebar extends StatelessWidget {
  final CreditNoteListController controller;
  const _DesktopSidebar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      height: MediaQuery.of(context).size.height - kToolbarHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey.shade300)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(2, 0))],
      ),
      child: Column(
        children: [
          _buildSidebarHeader(),
          _SearchField(controller: controller),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  _StatsSection(controller: controller),
                  const SizedBox(height: 14),
                  _FilterSection(controller: controller),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader() {
    return Container(
      height: 70,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [ElegantLightTheme.primaryBlue.withValues(alpha: 0.1), ElegantLightTheme.primaryBlue.withValues(alpha: 0.05)],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.receipt_long, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Notas de Crédito', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: ElegantLightTheme.primaryBlue)),
              Text('Panel de Control', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final CreditNoteListController controller;
  const _SearchField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          gradient: ElegantLightTheme.glassGradient,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: ElegantLightTheme.textSecondary.withValues(alpha: 0.2)),
        ),
        child: TextField(
          controller: controller.searchController,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Buscar notas...',
            hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            prefixIcon: Icon(Icons.search, size: 18, color: Colors.grey.shade500),
            suffixIcon: Obx(() => controller.searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () => controller.searchController.clear(),
                  )
                : const SizedBox.shrink()),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ),
    );
  }
}

class _StatsSection extends StatelessWidget {
  final CreditNoteListController controller;
  const _StatsSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final total = controller.creditNotes.length;
      final drafts = controller.creditNotes.where((c) => c.status == CreditNoteStatus.draft).length;
      final confirmed = controller.creditNotes.where((c) => c.status == CreditNoteStatus.confirmed).length;
      final cancelled = controller.creditNotes.where((c) => c.status == CreditNoteStatus.cancelled).length;

      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: ElegantLightTheme.glassGradient,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ElegantLightTheme.textSecondary.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(gradient: ElegantLightTheme.primaryGradient, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.analytics, size: 14, color: Colors.white),
                ),
                const SizedBox(width: 10),
                const Text('Estadísticas', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 14),
            _StatRow(label: 'Total', value: total.toString(), icon: Icons.receipt_long, color: ElegantLightTheme.primaryBlue),
            const SizedBox(height: 8),
            _StatRow(label: 'Borradores', value: drafts.toString(), icon: Icons.edit, color: Colors.grey),
            const SizedBox(height: 8),
            _StatRow(label: 'Confirmadas', value: confirmed.toString(), icon: Icons.check_circle, color: const Color(0xFF10B981)),
            const SizedBox(height: 8),
            _StatRow(label: 'Canceladas', value: cancelled.toString(), icon: Icons.cancel, color: Colors.red),
          ],
        ),
      );
    });
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatRow({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.7)]),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 14, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.8)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  final CreditNoteListController controller;
  const _FilterSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: ElegantLightTheme.glassGradient,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ElegantLightTheme.textSecondary.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(gradient: ElegantLightTheme.warningGradient, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.filter_list, size: 14, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  const Text('Filtros', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 14),
              const Text('Estado', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: ElegantLightTheme.textSecondary)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _FilterChipWidget(label: 'Todos', isSelected: controller.selectedStatus == null, color: Colors.grey, onTap: () => controller.setStatusFilter(null)),
                  _FilterChipWidget(label: 'Borrador', isSelected: controller.selectedStatus == CreditNoteStatus.draft, color: Colors.grey, onTap: () => controller.setStatusFilter(CreditNoteStatus.draft)),
                  _FilterChipWidget(label: 'Confirmada', isSelected: controller.selectedStatus == CreditNoteStatus.confirmed, color: const Color(0xFF10B981), onTap: () => controller.setStatusFilter(CreditNoteStatus.confirmed)),
                  _FilterChipWidget(label: 'Cancelada', isSelected: controller.selectedStatus == CreditNoteStatus.cancelled, color: Colors.red, onTap: () => controller.setStatusFilter(CreditNoteStatus.cancelled)),
                ],
              ),
              const SizedBox(height: 14),
              const Text('Tipo', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: ElegantLightTheme.textSecondary)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _FilterChipWidget(label: 'Todos', isSelected: controller.selectedType == null, color: Colors.grey, onTap: () => controller.setTypeFilter(null)),
                  _FilterChipWidget(label: 'Completa', isSelected: controller.selectedType == CreditNoteType.full, color: Colors.purple, onTap: () => controller.setTypeFilter(CreditNoteType.full)),
                  _FilterChipWidget(label: 'Parcial', isSelected: controller.selectedType == CreditNoteType.partial, color: Colors.teal, onTap: () => controller.setTypeFilter(CreditNoteType.partial)),
                ],
              ),
              if (controller.hasFilters) ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: InkWell(
                    onTap: controller.clearFilters,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.clear_all, size: 16, color: Colors.orange),
                          SizedBox(width: 6),
                          Text('Limpiar Filtros', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.orange)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ));
  }
}

class _FilterChipWidget extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChipWidget({required this.label, required this.isSelected, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 95,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? LinearGradient(colors: [color, color.withValues(alpha: 0.8)]) : null,
          color: isSelected ? null : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? color.withValues(alpha: 0.5) : Colors.grey.shade300),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, color: isSelected ? Colors.white : Colors.grey.shade700),
        ),
      ),
    );
  }
}

class _DesktopToolbar extends StatelessWidget {
  final CreditNoteListController controller;
  const _DesktopToolbar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Obx(() => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Notas de Crédito (${controller.creditNotes.length})',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    if (controller.paginationMeta != null)
                      Text(
                        'Página ${controller.currentPage} de ${controller.paginationMeta!.totalPages}',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                  ],
                )),
          ),
          ElevatedButton.icon(
            onPressed: () => controller.goToCreate(),
            icon: const Icon(Icons.add_circle_outline, size: 18),
            label: const Text('Nueva Nota'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ElegantLightTheme.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}

class _FiltersBottomSheet extends StatelessWidget {
  final CreditNoteListController controller;
  const _FiltersBottomSheet({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: ElegantLightTheme.cardGradient,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: ElegantLightTheme.textTertiary.withValues(alpha: 0.2)),
        ),
        child: Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(gradient: ElegantLightTheme.primaryGradient, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.filter_list, size: 18, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('Filtros', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 16),
              _FilterSection(controller: controller),
            ],
          ),
        ),
      ),
    );
  }
}
