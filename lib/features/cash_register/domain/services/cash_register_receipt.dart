// lib/features/cash_register/domain/services/cash_register_receipt.dart
import '../../../../app/core/printing/receipt_line.dart';
import '../../../../app/core/utils/formatters.dart';
import '../entities/cash_register.dart';

/// Arma el recibo de caja para la impresora térmica.
///
/// - Caja ABIERTA: "ARQUEO DE CAJA" con lo que va del turno ([summary] y
///   [expected] llegan del estado actual).
/// - Caja CERRADA: "CIERRE DE CAJA" con el resumen guardado, lo contado y la
///   diferencia.
///
/// Muestra por separado el efectivo (lo que debe haber en el cajón) y los
/// cobros por otros medios (Bre-B, transferencias, tarjetas), que no están en
/// la caja. No sabe nada de la impresora: devuelve las líneas.
List<ReceiptLine> buildCashRegisterReceipt({
  required CashRegister register,
  required String businessName,
  CashRegisterSummary? summary,
  double? expected,
  DateTime? printedAt,
}) {
  final s = summary ?? register.closingSummary ?? CashRegisterSummary.empty;
  final closed = register.closedAt != null;
  final expectedCash = expected ?? register.closingExpectedAmount ?? s.expectedCash(register.openingAmount);
  String money(num value) => AppFormatters.formatCurrency(value);
  String count(int? n, String one, String many) => n == null ? '' : ' ($n ${n == 1 ? one : many})';

  final lines = <ReceiptLine>[
    ReceiptLine.title(businessName.trim().isEmpty ? 'Baudex' : businessName.trim()),
    ReceiptLine.center(closed ? 'CIERRE DE CAJA' : 'ARQUEO DE CAJA', bold: true),
    if (!closed) const ReceiptLine.center('(la caja sigue abierta)'),
    const ReceiptLine.divider(),
    ReceiptLine.amount('Apertura', AppFormatters.formatDateTime(register.openedAt)),
    if ((register.openedByName ?? '').isNotEmpty) ReceiptLine.amount('Abrió', register.openedByName!),
    if (closed) ReceiptLine.amount('Cierre', AppFormatters.formatDateTime(register.closedAt)),
    if (closed && (register.closedByName ?? '').isNotEmpty) ReceiptLine.amount('Cerró', register.closedByName!),
    const ReceiptLine.divider(),

    // ── Efectivo: lo que debe haber en el cajón ──
    const ReceiptLine('EFECTIVO EN CAJA', bold: true),
    ReceiptLine.amount('Base inicial', money(register.openingAmount)),
    if (s.hasBreakdown) ...[
      ReceiptLine.amount('+ Ventas${count(s.cashFromSalesCount, 'pago', 'pagos')}', money(s.cashFromSales ?? 0)),
      ReceiptLine.amount(
        '+ Abonos a créditos${count(s.cashFromCreditPaymentsCount, 'abono', 'abonos')}',
        money(s.cashFromCreditPayments ?? 0),
      ),
    ] else
      ReceiptLine.amount('+ Efectivo recibido${count(s.cashSalesCount, 'pago', 'pagos')}', money(s.cashSales)),
    if (s.cashDeposits > 0) ReceiptLine.amount('+ Depósitos', money(s.cashDeposits)),
    ReceiptLine.amount('- Gastos de caja${count(s.cashExpensesCount, 'gasto', 'gastos')}', money(s.cashExpenses)),
    if (s.cashWithdrawals > 0) ReceiptLine.amount('- Retiros', money(s.cashWithdrawals)),
    ReceiptLine.amount('= DEBE HABER', money(expectedCash), bold: true),
    if (closed && register.closingActualAmount != null) ...[
      ReceiptLine.amount('Contado', money(register.closingActualAmount!)),
      ReceiptLine.amount(
        _differenceLabel(register.closingDifference ?? 0),
        money((register.closingDifference ?? 0).abs()),
        bold: true,
      ),
    ],
  ];

  // ── Otros medios: dinero que entró, pero no al cajón ──
  if (s.hasBreakdown) {
    lines
      ..add(const ReceiptLine.divider())
      ..add(const ReceiptLine('OTROS MEDIOS (no están en la caja)', bold: true));
    final others = s.otherMethods ?? const <OtherMethodTotal>[];
    if (others.isEmpty) {
      lines.add(const ReceiptLine('Sin cobros por otros medios'));
    } else {
      for (final m in others) {
        lines.add(ReceiptLine.amount('${otherMethodDisplayName(m)}${count(m.count, 'pago', 'pagos')}', money(m.total)));
      }
      lines.add(ReceiptLine.amount('Total otros medios', money(s.otherMethodsTotal ?? 0), bold: true));
    }
    lines
      ..add(const ReceiptLine.divider())
      ..add(ReceiptLine.amount('TOTAL COBRADO', money(s.totalCollected ?? s.cashSales), bold: true));
    if ((s.creditSalesTotal ?? 0) > 0) {
      lines.add(ReceiptLine.amount(
        'Ventas fiadas${count(s.creditSalesCount, 'venta', 'ventas')}',
        money(s.creditSalesTotal!),
      ));
    }
    if ((s.brebAdjustmentsTotal ?? 0) > 0) {
      lines.add(ReceiptLine.amount('Ajustes Bre-B (no cobrado)', money(s.brebAdjustmentsTotal!)));
    }
  }
  if (s.creditNotesTotal > 0) {
    lines.add(ReceiptLine.amount(
      'Notas crédito${count(s.creditNotesCount, 'nota', 'notas')}',
      money(s.creditNotesTotal),
    ));
  }

  if (closed && (register.closingNotes ?? '').trim().isNotEmpty) {
    lines
      ..add(const ReceiptLine.divider())
      ..add(const ReceiptLine('Notas del cierre:', bold: true))
      ..add(ReceiptLine(register.closingNotes!.trim()));
  }

  lines
    ..add(const ReceiptLine.divider())
    ..add(ReceiptLine('Impreso: ${AppFormatters.formatDateTime(printedAt ?? DateTime.now())}', feedAfter: 2))
    ..add(const ReceiptLine.center('_____________________________'))
    ..add(const ReceiptLine.center('Firma responsable'));
  return lines;
}

String _differenceLabel(double difference) {
  if (difference == 0) return 'DIFERENCIA (cuadra)';
  return difference > 0 ? 'SOBRANTE' : 'FALTANTE';
}

/// Nombre para mostrar de un medio de pago del desglose de la caja.
/// Bre-B llega del servidor con su propio nombre ("Bre-B" o "Bre-B · cuenta").
/// Al imprimir, las tildes y símbolos se quitan en la capa de impresión.
String otherMethodDisplayName(OtherMethodTotal m) {
  if (m.method == 'breb') {
    return m.label.isEmpty || m.label == m.method ? 'Bre-B' : m.label;
  }
  const names = <String, String>{
    'bank_transfer': 'Transferencia',
    'credit_card': 'Tarjeta de crédito',
    'debit_card': 'Tarjeta débito',
    'check': 'Cheque',
    'other': 'Otro medio',
  };
  final methodName = names[m.method] ?? m.method;
  if (m.label.isEmpty || m.label == m.method) return methodName;
  return '${m.label} · $methodName';
}
