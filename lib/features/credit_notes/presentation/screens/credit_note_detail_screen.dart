// lib/features/credit_notes/presentation/screens/credit_note_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../../app/core/utils/responsive_helper.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../domain/entities/credit_note.dart';
import '../controllers/credit_note_detail_controller.dart';
import '../widgets/credit_note_status_widget.dart';

class CreditNoteDetailScreen extends GetView<CreditNoteDetailController> {
  const CreditNoteDetailScreen({super.key});

  // ✅ Usar ResponsiveHelper para consistencia con el resto de la app
  bool _isDesktop(BuildContext context) => ResponsiveHelper.isDesktop(context);
  bool _isTablet(BuildContext context) => ResponsiveHelper.isTablet(context);
  bool _isMobile(BuildContext context) => ResponsiveHelper.isMobile(context);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ElegantLightTheme.backgroundColor,
      appBar: _buildAppBar(context),
      body: Obx(() {
        if (controller.isLoading) return _buildLoadingState(context);
        if (!controller.hasData) return _buildErrorState(context);

        final creditNote = controller.creditNote!;

        if (_isDesktop(context)) {
          return _buildDesktopLayout(context, creditNote);
        } else if (_isTablet(context)) {
          return _buildTabletLayout(context, creditNote);
        } else {
          return _buildMobileLayout(context, creditNote);
        }
      }),
      floatingActionButton: _buildFAB(context),
    );
  }

  // ==================== APP BAR ====================
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final isSmall = _isMobile(context);
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      toolbarHeight: isSmall ? 52 : 56,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: ElegantLightTheme.primaryGradient,
          boxShadow: [
            BoxShadow(
              color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
      leading: _buildAppBarButton(Icons.arrow_back, () => Get.back(), isSmall),
      title: Obx(() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            controller.creditNote?.number ?? 'Nota de Crédito',
            style: TextStyle(fontSize: isSmall ? 15 : 17, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          if (controller.hasData)
            Text(
              controller.creditNote!.customerName,
              style: TextStyle(fontSize: isSmall ? 11 : 12, color: Colors.white70),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      )),
      actions: [
        Obx(() {
          if (controller.creditNote?.canBeEdited == true) {
            return _buildAppBarButton(Icons.edit, controller.goToEdit, isSmall);
          }
          return const SizedBox.shrink();
        }),
        _buildAppBarButton(Icons.refresh, controller.refreshCreditNote, isSmall),
        _buildMoreMenu(context, isSmall),
        SizedBox(width: isSmall ? 6 : 8),
      ],
    );
  }

  Widget _buildAppBarButton(IconData icon, VoidCallback onTap, bool isSmall) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isSmall ? 3 : 4, vertical: isSmall ? 10 : 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: EdgeInsets.all(isSmall ? 7 : 8),
          child: Icon(icon, color: Colors.white, size: isSmall ? 18 : 20),
        ),
      ),
    );
  }

  Widget _buildMoreMenu(BuildContext context, bool isSmall) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isSmall ? 3 : 4, vertical: isSmall ? 10 : 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        icon: Icon(Icons.more_vert, color: Colors.white, size: isSmall ? 18 : 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onSelected: _handleMenuAction,
        itemBuilder: (context) => [
          _buildMenuItem('pdf', 'Descargar PDF', Icons.picture_as_pdf, Colors.red),
          _buildMenuItem('invoice', 'Ver Factura', Icons.receipt, Colors.orange),
          _buildMenuItem('customer', 'Ver Cliente', Icons.person, Colors.blue),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildMenuItem(String value, String label, IconData icon, Color color) {
    return PopupMenuItem(
      value: value,
      height: 44,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 14, color: ElegantLightTheme.textPrimary)),
        ],
      ),
    );
  }

  // ==================== STATES ====================
  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: ElegantLightTheme.glowShadow,
            ),
            child: const Icon(Icons.receipt_long, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 20),
          const Text('Cargando...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ElegantLightTheme.textPrimary)),
          const SizedBox(height: 16),
          SizedBox(
            width: 150,
            child: LinearProgressIndicator(
              backgroundColor: ElegantLightTheme.textSecondary.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(ElegantLightTheme.primaryBlue),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: ElegantLightTheme.cardGradient,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
          boxShadow: ElegantLightTheme.elevatedShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(gradient: ElegantLightTheme.errorGradient, borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.error_outline, color: Colors.white, size: 48),
            ),
            const SizedBox(height: 20),
            const Text('Nota no encontrada', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: ElegantLightTheme.textPrimary)),
            const SizedBox(height: 8),
            Text('La nota de crédito no existe', style: TextStyle(fontSize: 14, color: ElegantLightTheme.textSecondary)),
            const SizedBox(height: 24),
            _buildActionButton('Volver', Icons.arrow_back, () => Get.back(), ElegantLightTheme.primaryGradient),
          ],
        ),
      ),
    );
  }

  // ==================== DESKTOP LAYOUT ====================
  // Organizado en FILAS con altura simétrica
  Widget _buildDesktopLayout(BuildContext context, CreditNote creditNote) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // === FILA 1: Header con info principal ===
          _buildDesktopHeader(context, creditNote),
          const SizedBox(height: 20),

          // === FILA 2: Cliente | Factura | Motivo (3 cards misma altura) ===
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _buildMiniCard(
                  icon: Icons.person,
                  iconColor: Colors.blue,
                  title: 'Cliente',
                  value: creditNote.customerName,
                  onTap: controller.goToCustomer,
                )),
                const SizedBox(width: 16),
                Expanded(child: _buildMiniCard(
                  icon: Icons.receipt,
                  iconColor: Colors.orange,
                  title: 'Factura',
                  value: creditNote.invoiceNumber,
                  subtitle: AppFormatters.formatCurrency(creditNote.invoiceTotal),
                  onTap: controller.goToInvoice,
                )),
                const SizedBox(width: 16),
                Expanded(child: _buildMiniCard(
                  icon: creditNote.reasonIcon,
                  iconColor: Colors.purple,
                  title: 'Motivo',
                  value: creditNote.reasonDisplayName,
                )),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // === FILA 3: Items (izq) | Totales + Acciones (der) ===
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Items - ocupa más espacio
                Expanded(
                  flex: 6,
                  child: _buildItemsCard(context, creditNote, isDesktop: true),
                ),
                const SizedBox(width: 20),
                // Totales + Acciones en columna
                Expanded(
                  flex: 4,
                  child: Column(
                    children: [
                      _buildTotalsCard(context, creditNote, isDesktop: true),
                      const SizedBox(height: 16),
                      Expanded(child: _buildActionsCard(context, creditNote, isDesktop: true)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // === FILA 4 (opcional): Notas | Inventario ===
          if (creditNote.notes?.isNotEmpty == true || creditNote.restoreInventory) ...[
            const SizedBox(height: 20),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (creditNote.notes?.isNotEmpty == true)
                    Expanded(child: _buildNotesCard(context, creditNote, isDesktop: true)),
                  if (creditNote.notes?.isNotEmpty == true && creditNote.restoreInventory)
                    const SizedBox(width: 16),
                  if (creditNote.restoreInventory)
                    Expanded(child: _buildInventoryCard(context, creditNote, isDesktop: true)),
                  // Si solo hay uno, agregar spacer para balance
                  if (creditNote.notes?.isNotEmpty != true || !creditNote.restoreInventory)
                    const Expanded(child: SizedBox()),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDesktopHeader(BuildContext context, CreditNote creditNote) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ElegantLightTheme.textTertiary.withValues(alpha: 0.1)),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.primaryGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: ElegantLightTheme.glowShadow,
            ),
            child: const Icon(Icons.receipt_long, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(creditNote.number, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: ElegantLightTheme.textPrimary)),
                    const SizedBox(width: 12),
                    CreditNoteStatusWidget(creditNote: creditNote, isCompact: false),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _buildChip(Icons.calendar_today, AppFormatters.formatDate(creditNote.date), Colors.grey),
                    const SizedBox(width: 10),
                    _buildChip(
                      creditNote.isFullCredit ? Icons.all_inclusive : Icons.pie_chart,
                      creditNote.typeDisplayName,
                      creditNote.isFullCredit ? Colors.purple : Colors.teal,
                    ),
                    const SizedBox(width: 10),
                    _buildChip(Icons.list_alt, '${creditNote.items.length} items', Colors.indigo),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.successGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: const Color(0xFF10B981).withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              children: [
                const Text('TOTAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white70)),
                const SizedBox(height: 2),
                Text(AppFormatters.formatCurrency(creditNote.total), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _buildMiniCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    final content = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: iconColor.withValues(alpha: 0.15)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [iconColor, iconColor.withValues(alpha: 0.7)]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: TextStyle(fontSize: 11, color: ElegantLightTheme.textTertiary)),
                const SizedBox(height: 3),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ElegantLightTheme.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: ElegantLightTheme.textSecondary)),
                ],
              ],
            ),
          ),
          if (onTap != null)
            Icon(Icons.chevron_right, size: 20, color: ElegantLightTheme.textTertiary),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(14), child: content);
    }
    return content;
  }

  // ==================== TABLET LAYOUT ====================
  Widget _buildTabletLayout(BuildContext context, CreditNote creditNote) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // === FILA 1: Header ===
          _buildTabletHeader(context, creditNote),
          const SizedBox(height: 16),

          // === FILA 2: Cliente | Factura (2 cards misma altura) ===
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _buildMiniCard(
                  icon: Icons.person,
                  iconColor: Colors.blue,
                  title: 'Cliente',
                  value: creditNote.customerName,
                  onTap: controller.goToCustomer,
                )),
                const SizedBox(width: 12),
                Expanded(child: _buildMiniCard(
                  icon: Icons.receipt,
                  iconColor: Colors.orange,
                  title: 'Factura',
                  value: creditNote.invoiceNumber,
                  subtitle: AppFormatters.formatCurrency(creditNote.invoiceTotal),
                  onTap: controller.goToInvoice,
                )),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // === FILA 3: Motivo (ancho completo) ===
          _buildMiniCard(
            icon: creditNote.reasonIcon,
            iconColor: Colors.purple,
            title: 'Motivo',
            value: creditNote.reasonDisplayName,
            subtitle: creditNote.reasonDescription,
          ),
          const SizedBox(height: 16),

          // === FILA 4: Items | Totales ===
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 6, child: _buildItemsCard(context, creditNote, isTablet: true)),
                const SizedBox(width: 16),
                Expanded(flex: 4, child: _buildTotalsCard(context, creditNote, isTablet: true)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // === FILA 5: Acciones | Inventario (si aplica) ===
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _buildActionsCard(context, creditNote, isTablet: true)),
                if (creditNote.restoreInventory) ...[
                  const SizedBox(width: 12),
                  Expanded(child: _buildInventoryCard(context, creditNote, isTablet: true)),
                ],
              ],
            ),
          ),

          // === FILA 6: Notas (si hay) ===
          if (creditNote.notes?.isNotEmpty == true) ...[
            const SizedBox(height: 16),
            _buildNotesCard(context, creditNote, isTablet: true),
          ],
        ],
      ),
    );
  }

  Widget _buildTabletHeader(BuildContext context, CreditNote creditNote) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ElegantLightTheme.textTertiary.withValues(alpha: 0.1)),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(gradient: ElegantLightTheme.primaryGradient, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.receipt_long, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(child: Text(creditNote.number, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: ElegantLightTheme.textPrimary))),
                    const SizedBox(width: 10),
                    CreditNoteStatusWidget(creditNote: creditNote, isCompact: true),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _buildChip(Icons.calendar_today, AppFormatters.formatDate(creditNote.date), Colors.grey),
                    _buildChip(creditNote.isFullCredit ? Icons.all_inclusive : Icons.pie_chart, creditNote.typeDisplayName, creditNote.isFullCredit ? Colors.purple : Colors.teal),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(gradient: ElegantLightTheme.successGradient, borderRadius: BorderRadius.circular(10)),
            child: Text(AppFormatters.formatCurrency(creditNote.total), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ==================== MOBILE LAYOUT ====================
  Widget _buildMobileLayout(BuildContext context, CreditNote creditNote) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _buildMobileHeader(context, creditNote),
          const SizedBox(height: 12),
          // Info cards en grid 2x2 para simetría
          Row(
            children: [
              Expanded(child: _buildMobileMiniCard(Icons.person, Colors.blue, 'Cliente', creditNote.customerName, onTap: controller.goToCustomer)),
              const SizedBox(width: 10),
              Expanded(child: _buildMobileMiniCard(Icons.receipt, Colors.orange, 'Factura', creditNote.invoiceNumber, onTap: controller.goToInvoice)),
            ],
          ),
          const SizedBox(height: 10),
          _buildMobileMiniCard(creditNote.reasonIcon, Colors.purple, 'Motivo', creditNote.reasonDisplayName),
          const SizedBox(height: 12),
          _buildItemsCard(context, creditNote, isMobile: true),
          const SizedBox(height: 12),
          _buildTotalsCard(context, creditNote, isMobile: true),
          if (creditNote.restoreInventory) ...[
            const SizedBox(height: 12),
            _buildInventoryCard(context, creditNote, isMobile: true),
          ],
          if (creditNote.notes?.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            _buildNotesCard(context, creditNote, isMobile: true),
          ],
          const SizedBox(height: 12),
          _buildActionsCard(context, creditNote, isMobile: true),
          const SizedBox(height: 70),
        ],
      ),
    );
  }

  Widget _buildMobileHeader(BuildContext context, CreditNote creditNote) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(gradient: ElegantLightTheme.primaryGradient, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.receipt_long, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(creditNote.number, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: ElegantLightTheme.textPrimary)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 10, color: ElegantLightTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text(AppFormatters.formatDate(creditNote.date), style: TextStyle(fontSize: 10, color: ElegantLightTheme.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CreditNoteStatusWidget(creditNote: creditNote, isCompact: true),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(gradient: ElegantLightTheme.successGradient, borderRadius: BorderRadius.circular(6)),
                child: Text(AppFormatters.formatCurrency(creditNote.total), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileMiniCard(IconData icon, Color color, String title, String value, {VoidCallback? onTap}) {
    final content = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.7)]), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 10, color: ElegantLightTheme.textTertiary)),
                Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ElegantLightTheme.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          if (onTap != null) Icon(Icons.chevron_right, size: 16, color: ElegantLightTheme.textTertiary),
        ],
      ),
    );
    if (onTap != null) return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(10), child: content);
    return content;
  }

  // ==================== SHARED COMPONENTS ====================

  Widget _buildCard({required Widget child, bool isDesktop = false, bool isTablet = false}) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 18 : isTablet ? 16 : 14),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(isDesktop ? 14 : 12),
        border: Border.all(color: ElegantLightTheme.textTertiary.withValues(alpha: 0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: child,
    );
  }

  Widget _buildCardHeader(String title, IconData icon, Color color, {bool isDesktop = false}) {
    final size = isDesktop ? 16.0 : 14.0;
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(isDesktop ? 8 : 6),
          decoration: BoxDecoration(gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.7)]), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: Colors.white, size: size),
        ),
        SizedBox(width: isDesktop ? 10 : 8),
        Text(title, style: TextStyle(fontSize: isDesktop ? 15 : 13, fontWeight: FontWeight.w700, color: ElegantLightTheme.textPrimary)),
      ],
    );
  }

  Widget _buildItemsCard(BuildContext context, CreditNote creditNote, {bool isDesktop = false, bool isTablet = false, bool isMobile = false}) {
    return _buildCard(
      isDesktop: isDesktop,
      isTablet: isTablet,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader('Items (${creditNote.items.length})', Icons.list_alt, Colors.indigo, isDesktop: isDesktop),
          SizedBox(height: isDesktop ? 14 : 12),
          if (isDesktop)
            _buildItemsTable(creditNote)
          else
            ...creditNote.items.asMap().entries.map((e) => _buildItemRow(e.key, e.value, isTablet: isTablet)),
        ],
      ),
    );
  }

  Widget _buildItemsTable(CreditNote creditNote) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(color: ElegantLightTheme.textTertiary.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(6)),
          child: const Row(
            children: [
              SizedBox(width: 32),
              Expanded(flex: 4, child: Text('Producto', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: ElegantLightTheme.textSecondary))),
              Expanded(flex: 1, child: Text('Cant.', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: ElegantLightTheme.textSecondary), textAlign: TextAlign.center)),
              Expanded(flex: 2, child: Text('Precio', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: ElegantLightTheme.textSecondary), textAlign: TextAlign.right)),
              Expanded(flex: 2, child: Text('Subtotal', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: ElegantLightTheme.textSecondary), textAlign: TextAlign.right)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        ...creditNote.items.asMap().entries.map((entry) {
          final item = entry.value;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(border: entry.key < creditNote.items.length - 1 ? Border(bottom: BorderSide(color: ElegantLightTheme.textTertiary.withValues(alpha: 0.08))) : null),
            child: Row(
              children: [
                Container(
                  width: 24, height: 24,
                  decoration: BoxDecoration(gradient: ElegantLightTheme.primaryGradient, borderRadius: BorderRadius.circular(5)),
                  child: Center(child: Text('${entry.key + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 10))),
                ),
                const SizedBox(width: 8),
                Expanded(flex: 4, child: Text(item.description, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ElegantLightTheme.textPrimary))),
                Expanded(flex: 1, child: Text('${item.quantity}', style: const TextStyle(fontSize: 13, color: ElegantLightTheme.textPrimary), textAlign: TextAlign.center)),
                Expanded(flex: 2, child: Text(AppFormatters.formatCurrency(item.unitPrice), style: TextStyle(fontSize: 13, color: ElegantLightTheme.textSecondary), textAlign: TextAlign.right)),
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                    child: Text(AppFormatters.formatCurrency(item.subtotal), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF10B981)), textAlign: TextAlign.right),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildItemRow(int index, dynamic item, {bool isTablet = false}) {
    return Container(
      margin: EdgeInsets.only(bottom: isTablet ? 8 : 6),
      padding: EdgeInsets.all(isTablet ? 10 : 8),
      decoration: BoxDecoration(
        color: ElegantLightTheme.textTertiary.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ElegantLightTheme.textTertiary.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: isTablet ? 24 : 22, height: isTablet ? 24 : 22,
            decoration: BoxDecoration(gradient: ElegantLightTheme.primaryGradient, borderRadius: BorderRadius.circular(5)),
            child: Center(child: Text('${index + 1}', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: isTablet ? 10 : 9))),
          ),
          SizedBox(width: isTablet ? 10 : 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.description, style: TextStyle(fontSize: isTablet ? 12 : 11, fontWeight: FontWeight.w600, color: ElegantLightTheme.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('${item.quantity} x ${AppFormatters.formatCurrency(item.unitPrice)}', style: TextStyle(fontSize: isTablet ? 10 : 9, color: ElegantLightTheme.textSecondary)),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: isTablet ? 8 : 6, vertical: isTablet ? 4 : 3),
            decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
            child: Text(AppFormatters.formatCurrency(item.subtotal), style: TextStyle(fontSize: isTablet ? 11 : 10, fontWeight: FontWeight.w700, color: const Color(0xFF10B981))),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalsCard(BuildContext context, CreditNote creditNote, {bool isDesktop = false, bool isTablet = false, bool isMobile = false}) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 18 : isTablet ? 16 : 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [const Color(0xFF10B981).withValues(alpha: 0.08), const Color(0xFF10B981).withValues(alpha: 0.03)]),
        borderRadius: BorderRadius.circular(isDesktop ? 14 : 12),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildCardHeader('Resumen', Icons.calculate, const Color(0xFF10B981), isDesktop: isDesktop),
          SizedBox(height: isDesktop ? 14 : 12),
          _buildTotalRow('Subtotal', creditNote.subtotal, isDesktop: isDesktop),
          SizedBox(height: isDesktop ? 8 : 6),
          _buildTotalRow('IVA (${creditNote.taxPercentage.toStringAsFixed(0)}%)', creditNote.taxAmount, isDesktop: isDesktop),
          SizedBox(height: isDesktop ? 12 : 8),
          Container(height: 1, color: const Color(0xFF10B981).withValues(alpha: 0.2)),
          SizedBox(height: isDesktop ? 12 : 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TOTAL', style: TextStyle(fontSize: isDesktop ? 15 : 13, fontWeight: FontWeight.w800, color: ElegantLightTheme.textPrimary)),
              Container(
                padding: EdgeInsets.symmetric(horizontal: isDesktop ? 14 : 10, vertical: isDesktop ? 8 : 6),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.successGradient,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [BoxShadow(color: const Color(0xFF10B981).withValues(alpha: 0.25), blurRadius: 6, offset: const Offset(0, 2))],
                ),
                child: Text(AppFormatters.formatCurrency(creditNote.total), style: TextStyle(fontSize: isDesktop ? 17 : 15, fontWeight: FontWeight.w800, color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount, {bool isDesktop = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: isDesktop ? 13 : 12, color: ElegantLightTheme.textSecondary)),
        Text(AppFormatters.formatCurrency(amount), style: TextStyle(fontSize: isDesktop ? 13 : 12, fontWeight: FontWeight.w600, color: ElegantLightTheme.textPrimary)),
      ],
    );
  }

  Widget _buildActionsCard(BuildContext context, CreditNote creditNote, {bool isDesktop = false, bool isTablet = false, bool isMobile = false}) {
    return Obx(() {
      if (controller.isProcessing) {
        return _buildCard(isDesktop: isDesktop, isTablet: isTablet, child: const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(strokeWidth: 2))));
      }

      final hasActions = creditNote.canBeConfirmed || creditNote.canBeCancelled || creditNote.canBeDeleted;
      if (!hasActions) {
        return _buildCard(
          isDesktop: isDesktop,
          isTablet: isTablet,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildCardHeader('Acciones', Icons.flash_on, ElegantLightTheme.primaryBlue, isDesktop: isDesktop),
              SizedBox(height: isDesktop ? 14 : 10),
              Icon(Icons.check_circle, color: Colors.green.withValues(alpha: 0.5), size: isDesktop ? 36 : 28),
              const SizedBox(height: 8),
              Text('Sin acciones pendientes', style: TextStyle(fontSize: isDesktop ? 13 : 11, color: ElegantLightTheme.textSecondary)),
            ],
          ),
        );
      }

      return _buildCard(
        isDesktop: isDesktop,
        isTablet: isTablet,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardHeader('Acciones', Icons.flash_on, ElegantLightTheme.primaryBlue, isDesktop: isDesktop),
            SizedBox(height: isDesktop ? 14 : 10),
            if (isMobile)
              Row(
                children: [
                  if (creditNote.canBeConfirmed) Expanded(child: _buildActionButton('Confirmar', Icons.check_circle, controller.confirmCreditNote, ElegantLightTheme.successGradient, isSmall: true)),
                  if (creditNote.canBeConfirmed && creditNote.canBeCancelled) const SizedBox(width: 8),
                  if (creditNote.canBeCancelled) Expanded(child: _buildActionButton('Cancelar', Icons.cancel, controller.cancelCreditNote, ElegantLightTheme.warningGradient, isSmall: true)),
                  if ((creditNote.canBeConfirmed || creditNote.canBeCancelled) && creditNote.canBeDeleted) const SizedBox(width: 8),
                  if (creditNote.canBeDeleted) Expanded(child: _buildActionButton('Eliminar', Icons.delete, controller.deleteCreditNote, ElegantLightTheme.errorGradient, isSmall: true)),
                ],
              )
            else
              Column(
                children: [
                  if (creditNote.canBeConfirmed) _buildActionButton('Confirmar Nota', Icons.check_circle, controller.confirmCreditNote, ElegantLightTheme.successGradient, fullWidth: true),
                  if (creditNote.canBeCancelled) ...[if (creditNote.canBeConfirmed) SizedBox(height: isDesktop ? 10 : 8), _buildActionButton('Cancelar Nota', Icons.cancel, controller.cancelCreditNote, ElegantLightTheme.warningGradient, fullWidth: true)],
                  if (creditNote.canBeDeleted) ...[if (creditNote.canBeConfirmed || creditNote.canBeCancelled) SizedBox(height: isDesktop ? 10 : 8), _buildActionButton('Eliminar Nota', Icons.delete, controller.deleteCreditNote, ElegantLightTheme.errorGradient, fullWidth: true)],
                ],
              ),
          ],
        ),
      );
    });
  }

  Widget _buildActionButton(String text, IconData icon, VoidCallback onTap, LinearGradient gradient, {bool fullWidth = false, bool isSmall = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: EdgeInsets.symmetric(vertical: isSmall ? 10 : 11, horizontal: isSmall ? 6 : 12),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [BoxShadow(color: gradient.colors.first.withValues(alpha: 0.25), blurRadius: 5, offset: const Offset(0, 2))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: isSmall ? 15 : 17),
            SizedBox(width: isSmall ? 4 : 6),
            Text(text, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: isSmall ? 11 : 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesCard(BuildContext context, CreditNote creditNote, {bool isDesktop = false, bool isTablet = false, bool isMobile = false}) {
    return _buildCard(
      isDesktop: isDesktop,
      isTablet: isTablet,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildCardHeader('Notas', Icons.notes, Colors.grey.shade600, isDesktop: isDesktop),
          SizedBox(height: isDesktop ? 12 : 10),
          Text(creditNote.notes ?? '', style: TextStyle(fontSize: isDesktop ? 13 : 12, color: ElegantLightTheme.textSecondary, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildInventoryCard(BuildContext context, CreditNote creditNote, {bool isDesktop = false, bool isTablet = false, bool isMobile = false}) {
    final isRestored = creditNote.inventoryRestored;
    final color = isRestored ? const Color(0xFF10B981) : Colors.orange;

    return Container(
      padding: EdgeInsets.all(isDesktop ? 16 : 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.withValues(alpha: 0.08), color.withValues(alpha: 0.03)]),
        borderRadius: BorderRadius.circular(isDesktop ? 14 : 12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isDesktop ? 10 : 8),
            decoration: BoxDecoration(gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.7)]), borderRadius: BorderRadius.circular(8)),
            child: Icon(isRestored ? Icons.check_circle : Icons.pending, color: Colors.white, size: isDesktop ? 20 : 18),
          ),
          SizedBox(width: isDesktop ? 12 : 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(isRestored ? 'Inventario Restaurado' : 'Pendiente de Restaurar', style: TextStyle(fontSize: isDesktop ? 13 : 12, fontWeight: FontWeight.w600, color: color)),
                if (creditNote.inventoryRestoredAt != null)
                  Text(AppFormatters.formatDateTime(creditNote.inventoryRestoredAt!), style: TextStyle(fontSize: isDesktop ? 11 : 10, color: ElegantLightTheme.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB(BuildContext context) {
    final isSmall = _isMobile(context);
    return Obx(() {
      if (!controller.hasData) return const SizedBox.shrink();

      if (controller.isDownloadingPdf) {
        return Container(
          width: isSmall ? 48 : 52, height: isSmall ? 48 : 52,
          decoration: BoxDecoration(gradient: ElegantLightTheme.primaryGradient, borderRadius: BorderRadius.circular(14), boxShadow: ElegantLightTheme.glowShadow),
          child: const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))),
        );
      }

      return Container(
        decoration: BoxDecoration(gradient: ElegantLightTheme.primaryGradient, borderRadius: BorderRadius.circular(14), boxShadow: ElegantLightTheme.glowShadow),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: controller.downloadPdf,
            borderRadius: BorderRadius.circular(14),
            child: Padding(padding: EdgeInsets.all(isSmall ? 13 : 15), child: Icon(Icons.picture_as_pdf, color: Colors.white, size: isSmall ? 22 : 24)),
          ),
        ),
      );
    });
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'pdf': controller.downloadPdf(); break;
      case 'invoice': controller.goToInvoice(); break;
      case 'customer': controller.goToCustomer(); break;
    }
  }
}
