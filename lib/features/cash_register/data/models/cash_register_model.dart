// lib/features/cash_register/data/models/cash_register_model.dart
import '../../domain/entities/cash_register.dart';

class CashRegisterSummaryModel extends CashRegisterSummary {
  const CashRegisterSummaryModel({
    required super.cashSales,
    required super.cashSalesCount,
    required super.cashExpenses,
    required super.cashExpensesCount,
    required super.cashDeposits,
    required super.cashWithdrawals,
    required super.invoicesCount,
    required super.creditNotesCount,
    required super.creditNotesTotal,
  });

  factory CashRegisterSummaryModel.fromJson(Map<String, dynamic> json) {
    return CashRegisterSummaryModel(
      cashSales: _toDouble(json['cashSales']),
      cashSalesCount: (json['cashSalesCount'] as num?)?.toInt() ?? 0,
      cashExpenses: _toDouble(json['cashExpenses']),
      cashExpensesCount: (json['cashExpensesCount'] as num?)?.toInt() ?? 0,
      cashDeposits: _toDouble(json['cashDeposits']),
      cashWithdrawals: _toDouble(json['cashWithdrawals']),
      invoicesCount: (json['invoicesCount'] as num?)?.toInt() ?? 0,
      creditNotesCount: (json['creditNotesCount'] as num?)?.toInt() ?? 0,
      creditNotesTotal: _toDouble(json['creditNotesTotal']),
    );
  }

  Map<String, dynamic> toJson() => {
        'cashSales': cashSales,
        'cashSalesCount': cashSalesCount,
        'cashExpenses': cashExpenses,
        'cashExpensesCount': cashExpensesCount,
        'cashDeposits': cashDeposits,
        'cashWithdrawals': cashWithdrawals,
        'invoicesCount': invoicesCount,
        'creditNotesCount': creditNotesCount,
        'creditNotesTotal': creditNotesTotal,
      };
}

class CashRegisterModel extends CashRegister {
  const CashRegisterModel({
    required super.id,
    required super.status,
    required super.openingAmount,
    super.closingExpectedAmount,
    super.closingActualAmount,
    super.closingDifference,
    super.closingSummary,
    required super.openedAt,
    required super.openedById,
    super.openedByName,
    super.closedAt,
    super.closedById,
    super.closedByName,
    super.openingNotes,
    super.closingNotes,
    required super.organizationId,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
  });

  factory CashRegisterModel.fromJson(Map<String, dynamic> json) {
    return CashRegisterModel(
      id: json['id'] as String,
      status: CashRegisterStatus.fromString(json['status'] as String?),
      openingAmount: _toDouble(json['openingAmount']),
      closingExpectedAmount: json['closingExpectedAmount'] != null
          ? _toDouble(json['closingExpectedAmount'])
          : null,
      closingActualAmount: json['closingActualAmount'] != null
          ? _toDouble(json['closingActualAmount'])
          : null,
      closingDifference: json['closingDifference'] != null
          ? _toDouble(json['closingDifference'])
          : null,
      closingSummary: json['closingSummary'] is Map
          ? CashRegisterSummaryModel.fromJson(
              Map<String, dynamic>.from(json['closingSummary'] as Map))
          : null,
      openedAt: _toDate(json['openedAt']),
      openedById: json['openedById'] as String,
      openedByName: _resolveUserName(json['openedBy']),
      closedAt: json['closedAt'] != null ? _toDate(json['closedAt']) : null,
      closedById: json['closedById'] as String?,
      closedByName: _resolveUserName(json['closedBy']),
      openingNotes: json['openingNotes'] as String?,
      closingNotes: json['closingNotes'] as String?,
      organizationId: json['organizationId'] as String,
      createdAt: _toDate(json['createdAt']),
      updatedAt: _toDate(json['updatedAt']),
      deletedAt: json['deletedAt'] != null ? _toDate(json['deletedAt']) : null,
    );
  }

  static String? _resolveUserName(dynamic user) {
    if (user is Map<String, dynamic>) {
      // Backend manda User con `firstName + lastName` o `fullName`
      final fullName = user['fullName'] as String?;
      if (fullName != null && fullName.isNotEmpty) return fullName;
      final firstName = user['firstName'] as String?;
      final lastName = user['lastName'] as String?;
      final composed = '${firstName ?? ''} ${lastName ?? ''}'.trim();
      return composed.isEmpty ? null : composed;
    }
    return null;
  }
}

/// Respuesta del endpoint /cash-register/current.
class CashRegisterCurrentStateModel extends CashRegisterCurrentState {
  const CashRegisterCurrentStateModel({
    super.cashRegister,
    super.summary,
    super.expectedAmount,
  });

  factory CashRegisterCurrentStateModel.fromJson(Map<String, dynamic> json) {
    final crJson = json['cashRegister'];
    final summaryJson = json['summary'];
    return CashRegisterCurrentStateModel(
      cashRegister: crJson is Map<String, dynamic>
          ? CashRegisterModel.fromJson(crJson)
          : null,
      summary: summaryJson is Map<String, dynamic>
          ? CashRegisterSummaryModel.fromJson(summaryJson)
          : CashRegisterSummary.empty,
      expectedAmount: _toDouble(json['expectedAmount']),
    );
  }
}

double _toDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0;
  return 0;
}

DateTime _toDate(dynamic v) {
  if (v is DateTime) return v;
  if (v is String) return DateTime.parse(v);
  return DateTime.now();
}
