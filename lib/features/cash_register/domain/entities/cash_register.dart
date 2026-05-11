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

/// Resumen del turno de caja — snapshot inmutable que el backend
/// genera al cierre y devuelve también para la caja abierta como
/// "estado en vivo".
class CashRegisterSummary extends Equatable {
  final double cashSales;
  final int cashSalesCount;
  final double cashExpenses;
  final int cashExpensesCount;
  final double cashDeposits;
  final double cashWithdrawals;
  final int invoicesCount;
  final int creditNotesCount;
  final double creditNotesTotal;

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
  });

  static const empty = CashRegisterSummary();

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
