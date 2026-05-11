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
      child: LayoutBuilder(
        builder: (context, constraints) {
          // En desktop el card vive dentro de un Expanded(flex: ...) con
          // altura limitada — si el contenido del tab es más alto que esa
          // altura disponible, hay overflow. Detectamos eso con
          // `hasBoundedHeight` y en ese caso envolvemos el contenido en un
          // SingleChildScrollView para que pueda scrollear. En mobile/tablet
          // el card crece con su contenido (`MainAxisSize.min`), así que no
          // hay constraint y mostramos el contenido tal cual.
          final bounded = constraints.hasBoundedHeight;
          final tabbed = _TabbedContent(stats: stats);

          final tabContent = bounded
              ? Expanded(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: tabbed,
                  ),
                )
              : tabbed;

          return Container(
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.cardGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: ElegantLightTheme.elevatedShadow,
            ),
            child: Column(
              mainAxisSize: bounded ? MainAxisSize.max : MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ===== Header con KPI principal =====
                _buildKpiHeader(
                  isMobile: isMobile,
                  netRevenue: netRevenue,
                  creditNotesTotal: stats.creditNotesTotal,
                  hasCreditNotes: hasCreditNotes,
                ),

                // ===== TabBar elegante con gradient en indicador =====
                Container(
                  decoration: BoxDecoration(
                    color: ElegantLightTheme.textTertiary.withValues(alpha: 0.04),
                    border: Border(
                      bottom: BorderSide(
                        color: ElegantLightTheme.textTertiary
                            .withValues(alpha: 0.15),
                        width: 1,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 6),
                  child: TabBar(
                    // Indicador "pill" con gradient en lugar de la línea de
                    // 3px que se veía simple. Queda flotante encima del tab
                    // activo.
                    indicator: BoxDecoration(
                      gradient: ElegantLightTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: ElegantLightTheme.primaryBlue
                              .withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicatorPadding: const EdgeInsets.symmetric(vertical: 4),
                    dividerColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor: ElegantLightTheme.textSecondary,
                    labelStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                    splashBorderRadius: BorderRadius.circular(12),
                    tabs: const [
                      // Los tabs se renderizan con width fijo (tab indicator
                      // size = tab); cuando "Por Operación" más icono + gap
                      // pasa por unos píxeles del ancho disponible, Flex
                      // tira overflow. `Flexible` + `overflow.ellipsis` deja
                      // que el texto se ajuste sin romper layout. Reducimos
                      // gap 8→6 para dar más margen al texto.
                      Tab(
                        height: 42,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.account_tree_rounded, size: 16),
                            SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Por Operación',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Tab(
                        height: 42,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.account_balance_wallet_rounded,
                                size: 16),
                            SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Por Canal',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ===== Contenido del tab activo (scrolleable si hay altura
                // constreñida) =====
                tabContent,
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildKpiHeader({
    required bool isMobile,
    required double netRevenue,
    required double creditNotesTotal,
    required bool hasCreditNotes,
  }) {
    // Header compacto en UNA fila: icono + (label + valor grande) + badge NCs.
    // Gana ~50px verticales vs el layout anterior (que tenía 2 rows
    // separados por SizedBox), dejando más espacio para el scroll del tab.
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 14 : 16,
        vertical: isMobile ? 10 : 12,
      ),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.successGradient,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icono
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.savings_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Label + valor grande en columna apretada (sin spacing extra)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  hasCreditNotes
                      ? 'Ingresos Netos (post-devoluciones)'
                      : 'Ingresos Netos del Período',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  AppFormatters.formatCurrency(netRevenue),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isMobile ? 22 : 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Badge de NCs (solo si hay)
          if (hasCreditNotes) ...[
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'NCs',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    '−${AppFormatters.formatCurrency(creditNotesTotal)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
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
}

/// Contenedor de los 2 tabs. Usa `AnimatedBuilder` sobre el TabController
/// para reactivar cuando cambia el tab — más robusto que listener manual
/// con setState (esto último causaba un `dependent._parent` assertion al
/// reconstruir el árbol vía LayoutBuilder/responsive switches).
class _TabbedContent extends StatelessWidget {
  final DashboardStats stats;
  const _TabbedContent({required this.stats});

  @override
  Widget build(BuildContext context) {
    final controller = DefaultTabController.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        // Renderizado LAZY del tab activo. NO usamos AnimatedSize aquí
        // porque dentro del path "bounded" el contenido está envuelto en
        // Expanded(SingleChildScrollView) y AnimatedSize fuerza re-layout
        // → `!_debugDoingThisLayout` assertion. La transición es
        // instantánea pero AnimatedSwitcher da un crossfade suave.
        final index = controller.index;
        final Widget child;
        if (index == 0) {
          child = KeyedSubtree(
            key: const ValueKey('tab-operation'),
            child: IncomeBreakdownWidget(stats: stats),
          );
        } else {
          child = KeyedSubtree(
            key: const ValueKey('tab-channel'),
            child: stats.cashFlow.hasAny
                ? CashFlowSummaryWidget(
                    cashFlow: stats.cashFlow,
                    creditNotesTotal: stats.creditNotesTotal,
                    creditNotesCount: stats.creditNotesCount,
                  )
                : const _EmptyChannelState(),
          );
        }
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) =>
              FadeTransition(opacity: animation, child: child),
          child: child,
        );
      },
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
