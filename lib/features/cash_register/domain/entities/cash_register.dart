// lib/features/cash_register/domain/entities/cash_register.dart
import 'package:equatable/equatable.dart';

enum CashRegisterStatus {
  open('open', 'Abierta'),
  closed('closed', 'Cerrada');

  const CashRegisterStatus(this.value, this.displayName);
  final String value;
  final String displayName;

  static CashRegisterStatus fromString(String? value) {
    return CashRegisterStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => CashRegisterStatus.closed,
    );
  }
}

/// Cobros del turno por un medio distinto al efectivo (Nequi, transferencia,
/// tarjeta...). Ese dinero NO está en la caja: está en la cuenta.
class OtherMethodTotal extends Equatable {
  /// Código del método (`bank_transfer`, `credit_card`...).
  final String method;

  /// Nombre para mostrar: la cuenta donde entró ("Nequi") o el método.
  final String label;
  final double total;
  final int count;

  const OtherMethodTotal({
    required this.method,
    required this.label,
    required this.total,
    required this.count,
  });

  @override
  List<Object?> get props => [method, label, total, count];
}

/// Resumen del turno de caja — snapshot inmutable que el backend
/// genera al cierre y devuelve también para la caja abierta como
/// "estado en vivo".
class CashRegisterSummary extends Equatable {
  /// Todo el efectivo que entró en el turno (ventas + abonos a créditos).
  final double cashSales;
  final int cashSalesCount;
  final double cashExpenses;
  final int cashExpensesCount;
  final double cashDeposits;
  final double cashWithdrawals;
  final int invoicesCount;
  final int creditNotesCount;
  final double creditNotesTotal;

  // ── Desglose del turno ────────────────────────────────────────────────
  // Vienen en `null` si el servidor aún no envía el desglose o si es un
  // cierre guardado antes de que existiera.

  /// Efectivo recibido por ventas.
  final double? cashFromSales;
  final int? cashFromSalesCount;

  /// Efectivo recibido por abonos a créditos (fiados que se pagaron).
  final double? cashFromCreditPayments;
  final int? cashFromCreditPaymentsCount;

  /// Cobros por otros medios; no entran a la caja.
  final List<OtherMethodTotal>? otherMethods;
  final double? otherMethodsTotal;
  final int? otherMethodsCount;

  /// Todo lo cobrado en el turno, por cualquier medio.
  final double? totalCollected;

  /// Ventas fiadas en el turno (todavía no es dinero recibido).
  final double? creditSalesTotal;
  final int? creditSalesCount;

  const CashRegisterSummary({
    this.cashSales = 0,
    this.cashSalesCount = 0,
    this.cashExpenses = 0,
    this.cashExpensesCount = 0,
    this.cashDeposits = 0,
    this.cashWithdrawals = 0,
    this.invoicesCount = 0,
    this.creditNotesCount = 0,
    this.creditNotesTotal = 0,
    this.cashFromSales,
    this.cashFromSalesCount,
    this.cashFromCreditPayments,
    this.cashFromCreditPaymentsCount,
    this.otherMethods,
    this.otherMethodsTotal,
    this.otherMethodsCount,
    this.totalCollected,
    this.creditSalesTotal,
    this.creditSalesCount,
  });

  static const empty = CashRegisterSummary();

  /// `true` si el servidor envió el desglose completo del turno.
  bool get hasBreakdown => cashFromSales != null && otherMethods != null;

  /// Dinero que debe haber físicamente en la caja: base inicial + efectivo
  /// recibido + depósitos − gastos pagados de caja − retiros. Los cobros por
  /// otros medios y las ventas fiadas NO entran aquí.
  double expectedCash(double openingAmount) =>
      openingAmount + cashSales + cashDeposits - cashExpenses - cashWithdrawals;

  @override
  List<Object?> get props => [
        cashSales,
        cashSalesCount,
        cashExpenses,
        cashExpensesCount,
        cashDeposits,
        cashWithdrawals,
        invoicesCount,
        creditNotesCount,
        creditNotesTotal,
        cashFromSales,
        cashFromSalesCount,
        cashFromCreditPayments,
        cashFromCreditPaymentsCount,
        otherMethods,
        otherMethodsTotal,
        otherMethodsCount,
        totalCollected,
        creditSalesTotal,
        creditSalesCount,
      ];
}

class CashRegister extends Equatable {
  final String id;
  final CashRegisterStatus status;
  final double openingAmount;
  final double? closingExpectedAmount;
  final double? closingActualAmount;
  final double? closingDifference;
  final CashRegisterSummary? closingSummary;
  final DateTime openedAt;
  final String openedById;
  final String? openedByName;
  final DateTime? closedAt;
  final String? closedById;
  final String? closedByName;
  final String? openingNotes;
  final String? closingNotes;
  final String organizationId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const CashRegister({
    required this.id,
    required this.status,
    required this.openingAmount,
    this.closingExpectedAmount,
    this.closingActualAmount,
    this.closingDifference,
    this.closingSummary,
    required this.openedAt,
    required this.openedById,
    this.openedByName,
    this.closedAt,
    this.closedById,
    this.closedByName,
    this.openingNotes,
    this.closingNotes,
    required this.organizationId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  bool get isOpen => status == CashRegisterStatus.open;
  bool get isClosed => status == CashRegisterStatus.closed;

  /// Tiempo que la caja lleva abierta (o estuvo abierta).
  Duration get duration {
    final end = closedAt ?? DateTime.now();
    return end.difference(openedAt);
  }

  @override
  List<Object?> get props => [
        id,
        status,
        openingAmount,
        closingExpectedAmount,
        closingActualAmount,
        closingDifference,
        closingSummary,
        openedAt,
        openedById,
        openedByName,
        closedAt,
        closedById,
        closedByName,
        openingNotes,
        closingNotes,
        organizationId,
        createdAt,
        updatedAt,
        deletedAt,
      ];
}

/// Snapshot completo del estado actual: caja abierta (si existe)
/// + summary en vivo + monto esperado calculado on-the-fly.
class CashRegisterCurrentState extends Equatable {
  final CashRegister? cashRegister;
  final CashRegisterSummary summary;
  final double expectedAmount;

  const CashRegisterCurrentState({
    this.cashRegister,
    this.summary = CashRegisterSummary.empty,
    this.expectedAmount = 0,
  });

  bool get hasOpenRegister => cashRegister != null;

  @override
  List<Object?> get props => [cashRegister, summary, expectedAmount];
}
