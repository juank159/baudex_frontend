// lib/features/credit_notes/presentation/widgets/invoice_credit_notes_widget.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../domain/entities/credit_note.dart';
import '../../domain/usecases/get_credit_notes_by_invoice.dart';
import '../screens/credit_note_form_screen.dart';
import '../bindings/credit_note_binding.dart';

/// Widget para mostrar las notas de crédito asociadas a una factura
class InvoiceCreditNotesWidget extends StatefulWidget {
  final String invoiceId;

  const InvoiceCreditNotesWidget({
    super.key,
    required this.invoiceId,
  });

  @override
  State<InvoiceCreditNotesWidget> createState() =>
      _InvoiceCreditNotesWidgetState();
}

class _InvoiceCreditNotesWidgetState extends State<InvoiceCreditNotesWidget> {
  final _isLoading = true.obs;
  final _creditNotes = <CreditNote>[].obs;

  @override
  void initState() {
    super.initState();
    // Asegurar que las dependencias base estén disponibles
    _ensureDependencies();
    _loadCreditNotes();
  }

  /// Asegura que las dependencias del feature estén registradas
  void _ensureDependencies() {
    if (!Get.isRegistered<GetCreditNotesByInvoice>()) {
      print('🔧 Inicializando dependencias de CreditNotes...');
      CreditNoteBinding().dependencies();
    }
  }

  Future<void> _loadCreditNotes() async {
    _isLoading.value = true;

    try {
      if (!Get.isRegistered<GetCreditNotesByInvoice>()) {
        print('⚠️  GetCreditNotesByInvoice no está registrado');
        _isLoading.value = false;
        return;
      }

      final useCase = Get.find<GetCreditNotesByInvoice>();
      final result = await useCase(widget.invoiceId);

      result.fold(
        (failure) {
          print('❌ Error al cargar notas de crédito: ${failure.message}');
        },
        (creditNotes) {
          _creditNotes.value = creditNotes;
          print('✅ ${creditNotes.length} notas de crédito cargadas');
        },
      );
    } finally {
      _isLoading.value = false;
    }
  }

  void _navigateToCreateCreditNote() {
    print('📝 Navegando a crear nota de crédito para factura: ${widget.invoiceId}');

    // Navegar con el binding que inicializa todas las dependencias automáticamente
    Get.to(
      () => const CreditNoteFormScreen(),
      binding: CreditNoteFormBinding(),
      arguments: {'invoiceId': widget.invoiceId},
    )?.then((_) {
      // Recargar las notas de crédito al regresar
      print('🔄 Regresando de crear nota de crédito, recargando lista...');
      _loadCreditNotes();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Responsive sizing
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    final isTablet = size.width >= 600 && size.width < 1024;
    final isDesktop = size.width >= 1024;

    return Obx(() {
      if (_isLoading.value) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                const SizedBox(height: 16),
                Text(
                  'Cargando notas de crédito...',
                  style: TextStyle(
                    color: ElegantLightTheme.textSecondary,
                    fontSize: isMobile ? 12 : isTablet ? 14 : 13,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      if (_creditNotes.isEmpty) {
        return _buildEmptyState(isMobile, isTablet, isDesktop);
      }

      return _buildCreditNotesList(isMobile, isTablet, isDesktop);
    });
  }

  Widget _buildEmptyState(bool isMobile, bool isTablet, bool isDesktop) {
    final iconSize = isMobile ? 48.0 : isTablet ? 64.0 : 56.0;
    final titleSize = isMobile ? 14.0 : isTablet ? 18.0 : 16.0;
    final subtitleSize = isMobile ? 11.0 : isTablet ? 14.0 : 12.0;
    final buttonHeight = isMobile ? 40.0 : isTablet ? 48.0 : 44.0;
    final buttonFontSize = isMobile ? 12.0 : isTablet ? 14.0 : 13.0;
    final spacing = isMobile ? 12.0 : isTablet ? 20.0 : 16.0;

    return Center(
      child: FuturisticContainer(
        padding: EdgeInsets.all(spacing * 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icono con gradiente
            Container(
              width: iconSize + (isMobile ? 16 : 24),
              height: iconSize + (isMobile ? 16 : 24),
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.primaryGradient,
                borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
                boxShadow: ElegantLightTheme.glowShadow,
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                size: iconSize,
                color: Colors.white,
              ),
            ),
            SizedBox(height: spacing),

            // Título
            Text(
              'No hay notas de crédito',
              style: TextStyle(
                color: ElegantLightTheme.textPrimary,
                fontSize: titleSize,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: spacing / 2),

            // Subtítulo
            Text(
              'Aún no se han creado notas de crédito\npara esta factura',
              style: TextStyle(
                color: ElegantLightTheme.textSecondary,
                fontSize: subtitleSize,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: spacing * 1.5),

            // Botón estilizado
            Container(
              height: buttonHeight,
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.primaryGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: ElegantLightTheme.primaryBlue.withValues(alpha:0.3),
                    offset: const Offset(0, 4),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _navigateToCreateCreditNote,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: spacing * 1.5,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_circle_outline,
                          color: Colors.white,
                          size: buttonFontSize + 4,
                        ),
                        SizedBox(width: spacing / 2),
                        Text(
                          'Crear Nota de Crédito',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: buttonFontSize,
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
      ),
    );
  }

  Widget _buildCreditNotesList(bool isMobile, bool isTablet, bool isDesktop) {
    final spacing = isMobile ? 8.0 : isTablet ? 12.0 : 10.0;
    final headerSize = isMobile ? 13.0 : isTablet ? 16.0 : 15.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header con contador y botón
        Padding(
          padding: EdgeInsets.only(bottom: spacing),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Título con contador
              Row(
                children: [
                  Icon(
                    Icons.receipt_long,
                    size: headerSize + 4,
                    color: ElegantLightTheme.primaryGradient.colors.first,
                  ),
                  SizedBox(width: spacing / 2),
                  Text(
                    'Notas de Crédito',
                    style: TextStyle(
                      fontSize: headerSize,
                      fontWeight: FontWeight.w700,
                      color: ElegantLightTheme.textPrimary,
                    ),
                  ),
                  SizedBox(width: spacing / 2),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: spacing / 1.5,
                      vertical: spacing / 4,
                    ),
                    decoration: BoxDecoration(
                      gradient: ElegantLightTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_creditNotes.length}',
                      style: TextStyle(
                        fontSize: headerSize - 4,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),

              // Botón agregar
              _buildAddButton(isMobile, isTablet, isDesktop),
            ],
          ),
        ),

        // Lista de notas de crédito
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _creditNotes.length,
          separatorBuilder: (context, index) => SizedBox(height: spacing),
          itemBuilder: (context, index) {
            final creditNote = _creditNotes[index];
            return _buildCreditNoteCard(
              creditNote,
              isMobile,
              isTablet,
              isDesktop,
            );
          },
        ),

        SizedBox(height: spacing),

        // Sección de totales
        _buildTotalSection(isMobile, isTablet, isDesktop),
      ],
    );
  }

  Widget _buildAddButton(bool isMobile, bool isTablet, bool isDesktop) {
    final buttonSize = isMobile ? 30.0 : isTablet ? 36.0 : 34.0;
    final iconSize = isMobile ? 16.0 : isTablet ? 18.0 : 17.0;

    return Container(
      width: buttonSize,
      height: buttonSize,
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.successGradient,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: ElegantLightTheme.successGradient.colors.first.withValues(alpha:0.3),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _navigateToCreateCreditNote,
          borderRadius: BorderRadius.circular(10),
          child: Icon(
            Icons.add,
            color: Colors.white,
            size: iconSize,
          ),
        ),
      ),
    );
  }

  Widget _buildCreditNoteCard(
    CreditNote creditNote,
    bool isMobile,
    bool isTablet,
    bool isDesktop,
  ) {
    final cardPadding = isMobile ? 8.0 : isTablet ? 12.0 : 10.0;
    final titleSize = isMobile ? 12.0 : isTablet ? 14.0 : 13.0;
    final subtitleSize = isMobile ? 10.0 : isTablet ? 11.0 : 10.5;
    final amountSize = isMobile ? 13.0 : isTablet ? 15.0 : 14.0;
    final avatarSize = isMobile ? 32.0 : isTablet ? 40.0 : 36.0;
    final iconSize = isMobile ? 16.0 : isTablet ? 20.0 : 18.0;

    return FuturisticContainer(
      isHoverable: true,
      onTap: () {
        Get.toNamed('/credit-notes/${creditNote.id}');
      },
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Row(
          children: [
            // Avatar con icono
            Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    creditNote.statusColor,
                    creditNote.statusColor.withValues(alpha:0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: creditNote.statusColor.withValues(alpha:0.3),
                    offset: const Offset(0, 2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Icon(
                creditNote.reasonIcon,
                color: Colors.white,
                size: iconSize,
              ),
            ),
            SizedBox(width: cardPadding),

            // Información principal
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Número y estado
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          creditNote.number,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: titleSize,
                            color: ElegantLightTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: cardPadding / 2),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: cardPadding * 0.75,
                          vertical: cardPadding / 4,
                        ),
                        decoration: BoxDecoration(
                          color: creditNote.statusColor.withValues(alpha:0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: creditNote.statusColor.withValues(alpha:0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          creditNote.statusDisplayName,
                          style: TextStyle(
                            fontSize: subtitleSize - 1,
                            fontWeight: FontWeight.w600,
                            color: creditNote.statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: cardPadding / 3),

                  // Razón y fecha
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          creditNote.reasonDisplayName,
                          style: TextStyle(
                            fontSize: subtitleSize,
                            color: ElegantLightTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: cardPadding / 2),
                        child: Text(
                          '•',
                          style: TextStyle(
                            color: ElegantLightTheme.textTertiary,
                          ),
                        ),
                      ),
                      Text(
                        AppFormatters.formatDate(creditNote.date),
                        style: TextStyle(
                          fontSize: subtitleSize,
                          color: ElegantLightTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(width: cardPadding),

            // Monto y tipo
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  AppFormatters.formatCurrency(creditNote.total),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: amountSize,
                    foreground: Paint()
                      ..shader = ElegantLightTheme.successGradient.createShader(
                        const Rect.fromLTWH(0, 0, 200, 70),
                      ),
                  ),
                ),
                SizedBox(height: cardPadding / 4),
                Text(
                  creditNote.typeDisplayName,
                  style: TextStyle(
                    fontSize: subtitleSize,
                    color: ElegantLightTheme.textTertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            SizedBox(width: cardPadding / 2),

            // Icono de flecha
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: subtitleSize + 2,
              color: ElegantLightTheme.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalSection(bool isMobile, bool isTablet, bool isDesktop) {
    final totalCredits = _creditNotes
        .where((cn) => cn.isConfirmed)
        .fold(0.0, (sum, cn) => sum + cn.total);

    if (totalCredits == 0) return const SizedBox.shrink();

    final padding = isMobile ? 10.0 : isTablet ? 14.0 : 12.0;
    final titleSize = isMobile ? 11.0 : isTablet ? 13.0 : 12.0;
    final amountSize = isMobile ? 14.0 : isTablet ? 16.0 : 15.0;
    final iconSize = isMobile ? 14.0 : isTablet ? 16.0 : 15.0;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ElegantLightTheme.successGradient.colors.first.withValues(alpha:0.1),
            ElegantLightTheme.successGradient.colors.last.withValues(alpha:0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ElegantLightTheme.successGradient.colors.first.withValues(alpha:0.2),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isMobile ? 6 : 8),
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.successGradient,
                    borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: iconSize,
                  ),
                ),
                SizedBox(width: padding / 1.5),
                Text(
                  'Total Créditos Confirmados',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: titleSize,
                    color: ElegantLightTheme.textPrimary,
                  ),
                ),
              ],
            ),
            Text(
              AppFormatters.formatCurrency(totalCredits),
              style: TextStyle(
                fontSize: amountSize,
                fontWeight: FontWeight.w700,
                foreground: Paint()
                  ..shader = ElegantLightTheme.successGradient.createShader(
                    const Rect.fromLTWH(0, 0, 200, 70),
                  ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
