import 'package:flutter/material.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../../app/core/utils/responsive_helper.dart';
import '../../domain/entities/dashboard_stats.dart';
import 'cash_flow_summary_widget.dart';
import 'income_breakdown_widget.dart';

/// Análisis financiero unificado del período.
///
/// Refactor (Phase D, Bloque A): consolida en un único widget las dos
/// vistas que antes vivían separadas en el dashboard:
///   - "Desglose de Ingresos" (origen del dinero — ventas nuevas, abonos
///     a deudas viejas, saldos a favor)
///   - "Resumen de Caja"     (canal por el que entró — ventas, préstamos,
///     anticipos)
///
/// Ambas hablan del mismo dinero del día desde ángulos distintos, así que
/// las metemos en un mismo card con TabBar. El KPI principal (Ingresos
/// Netos) se muestra UNA SOLA VEZ en el header, eliminando la duplicación
/// del "INGRESO REAL" + "CAJA NETA REAL" que aparecía dos veces.
///
/// Responsive: el TabBar funciona idéntico en móvil/tablet/desktop. La
/// altura interna se adapta al contenido del tab activo.
class FinancialAnalysisWidget extends StatelessWidget {
  final DashboardStats stats;

  const FinancialAnalysisWidget({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final hasCreditNotes = stats.creditNotesTotal > 0;
    final netRevenue = stats.effectiveNetRevenue;

    return DefaultTabController(
      length: 2,
      child: Container(
        decoration: BoxDecoration(
          gradient: ElegantLightTheme.cardGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: ElegantLightTheme.elevatedShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ===== Header con KPI principal =====
            _buildKpiHeader(
              isMobile: isMobile,
              netRevenue: netRevenue,
              creditNotesTotal: stats.creditNotesTotal,
              hasCreditNotes: hasCreditNotes,
            ),

            // ===== TabBar =====
            Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: ElegantLightTheme.textTertiary
                        .withValues(alpha: 0.15),
                  ),
                ),
              ),
              child: TabBar(
                indicatorColor: ElegantLightTheme.primaryBlue,
                indicatorWeight: 3,
                labelColor: ElegantLightTheme.primaryBlue,
                unselectedLabelColor: ElegantLightTheme.textSecondary,
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                tabs: const [
                  Tab(
                    icon: Icon(Icons.account_tree_rounded, size: 18),
                    text: 'Por Operación',
                    iconMargin: EdgeInsets.only(bottom: 2),
                  ),
                  Tab(
                    icon: Icon(Icons.account_balance_wallet_rounded, size: 18),
                    text: 'Por Canal',
                    iconMargin: EdgeInsets.only(bottom: 2),
                  ),
                ],
              ),
            ),

            // ===== Contenido de cada tab =====
            // Usamos altura intrínseca con AnimatedSize para que la altura
            // se adapte al tab activo sin saltos visuales.
            _TabbedContent(stats: stats),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiHeader({
    required bool isMobile,
    required double netRevenue,
    required double creditNotesTotal,
    required bool hasCreditNotes,
  }) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 16 : 20,
        isMobile ? 16 : 20,
        isMobile ? 16 : 20,
        isMobile ? 12 : 16,
      ),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.successGradient,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.savings_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Análisis del Período',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Ingresos Netos',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                AppFormatters.formatCurrency(netRevenue),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isMobile ? 26 : 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              if (hasCreditNotes) ...[
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '−${AppFormatters.formatCurrency(creditNotesTotal)} en NCs',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            hasCreditNotes
                ? 'Dinero cobrado menos devoluciones'
                : 'Dinero efectivamente cobrado en el período',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Contenedor de los 2 tabs. Lo separo a un widget aparte para poder usar
/// `AnimatedSize` que ajusta la altura del card al contenido del tab
/// activo (los 2 widgets son de altura distinta).
class _TabbedContent extends StatefulWidget {
  final DashboardStats stats;
  const _TabbedContent({required this.stats});

  @override
  State<_TabbedContent> createState() => _TabbedContentState();
}

class _TabbedContentState extends State<_TabbedContent> {
  TabController? _tabController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // El TabController vive en DefaultTabController (ancestor). NO se puede
    // resolver en initState porque depende del context inherited; debe
    // hacerse en didChangeDependencies. Adjuntamos el listener una sola vez.
    final newController = DefaultTabController.of(context);
    if (_tabController != newController) {
      _tabController?.removeListener(_onTabChanged);
      _tabController = newController;
      _tabController!.addListener(_onTabChanged);
    }
  }

  @override
  void dispose() {
    _tabController?.removeListener(_onTabChanged);
    super.dispose();
  }

  void _onTabChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final index = _tabController?.index ?? 0;
    // Renderizado LAZY del tab activo — evita el overflow de IndexedStack
    // (que tomaba el alto del child más grande aunque solo se viera uno).
    // AnimatedSize anima la transición de altura entre tabs.
    final Widget child;
    if (index == 0) {
      child = KeyedSubtree(
        key: const ValueKey('tab-operation'),
        child: IncomeBreakdownWidget(stats: widget.stats),
      );
    } else {
      child = KeyedSubtree(
        key: const ValueKey('tab-channel'),
        child: widget.stats.cashFlow.hasAny
            ? CashFlowSummaryWidget(
                cashFlow: widget.stats.cashFlow,
                creditNotesTotal: widget.stats.creditNotesTotal,
                creditNotesCount: widget.stats.creditNotesCount,
              )
            : const _EmptyChannelState(),
      );
    }
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: child,
    );
  }
}

class _EmptyChannelState extends StatelessWidget {
  const _EmptyChannelState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 48,
            color: ElegantLightTheme.textTertiary.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 12),
          Text(
            'Sin movimientos de canal',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: ElegantLightTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Aún no hay cobros, abonos a préstamos ni anticipos.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: ElegantLightTheme.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
