// lib/features/bank_accounts/domain/entities/bank_account_movement.dart
import 'package:equatable/equatable.dart';

/// Tipo de movimiento de cuenta bancaria. Espejo del enum backend.
/// Cada tipo determina si el monto suma (inflow) o resta (outflow) al saldo.
enum BankAccountMovementType {
  initialBalance('initial_balance', 'Saldo inicial', true),
  deposit('deposit', 'Depósito', true),
  withdrawal('withdrawal', 'Retiro', false),
  invoicePayment('invoice_payment', 'Pago de factura', true),
  creditPayment('credit_payment', 'Abono a crédito', true),
  expensePayment('expense_payment', 'Gasto pagado', false),
  transferOut('transfer_out', 'Transferencia salida', false),
  transferIn('transfer_in', 'Transferencia entrada', true),
  adjustment('adjustment', 'Ajuste', true),
  refund('refund', 'Reembolso', false);

  const BankAccountMovementType(this.value, this.displayName, this.isInflow);

  final String value;
  final String displayName;

  /// True = suma al saldo. False = resta. (Para `adjustment` el signo se
  /// determina vía `metadata.direction`; default suma.)
  final bool isInflow;

  bool get isOutflow => !isInflow;

  static BankAccountMovementType fromString(String value) {
    return BankAccountMovementType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => BankAccountMovementType.adjustment,
    );
  }
}

/// Movimiento histórico inmutable de una cuenta bancaria.
///
/// Cada cambio de saldo (cobro, pago, depósito, retiro, transferencia,
/// ajuste, reembolso) genera un movement con snapshot del balance posterior.
/// Espejo de `BankAccountMovement` del backend.
class BankAccountMovement extends Equatable {
  final String id;
  final String bankAccountId;
  final BankAccountMovementType type;

  /// Monto siempre positivo. El signo (entrada/salida) lo determina `type`.
  final double amount;

  /// Saldo de la cuenta DESPUÉS de aplicar este movimiento. Permite
  /// reconstruir saldo histórico sin recalcular.
  final double balanceAfter;

  final DateTime movementDate;
  final String? description;

  /// Tipo del documento que originó el movimiento ('invoice',
  /// 'credit_payment', 'expense', 'transfer').
  final String? referenceType;
  final String? referenceId;

  /// Para transferencias: ID de la cuenta contraparte.
  final String? counterpartyAccountId;

  /// Para transferencias: ID del movement contraparte (atómica).
  final String? counterpartyMovementId;

  final Map<String, dynamic>? metadata;
  final String organizationId;
  final String? createdById;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const BankAccountMovement({
    required this.id,
    required this.bankAccountId,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    required this.movementDate,
    this.description,
    this.referenceType,
    this.referenceId,
    this.counterpartyAccountId,
    this.counterpartyMovementId,
    this.metadata,
    required this.organizationId,
    this.createdById,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  @override
  List<Object?> get props => [
        id,
        bankAccountId,
        type,
        amount,
        balanceAfter,
        movementDate,
        description,
        referenceType,
        referenceId,
        counterpartyAccountId,
        counterpartyMovementId,
        metadata,
        organizationId,
        createdById,
        createdAt,
        updatedAt,
        deletedAt,
      ];

  /// Monto firmado: positivo si suma, negativo si resta.
  double get signedAmount {
    if (type == BankAccountMovementType.adjustment) {
      // Ajustes: revisar metadata.direction
      final dir = metadata?['direction'];
      if (dir == 'subtract') return -amount;
      return amount;
    }
    return type.isInflow ? amount : -amount;
  }

  BankAccountMovement copyWith({
    String? id,
    String? bankAccountId,
    BankAccountMovementType? type,
    double? amount,
    double? balanceAfter,
    DateTime? movementDate,
    String? description,
    String? referenceType,
    String? referenceId,
    String? counterpartyAccountId,
    String? counterpartyMovementId,
    Map<String, dynamic>? metadata,
    String? organizationId,
    String? createdById,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return BankAccountMovement(
      id: id ?? this.id,
      bankAccountId: bankAccountId ?? this.bankAccountId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      balanceAfter: balanceAfter ?? this.balanceAfter,
      movementDate: movementDate ?? this.movementDate,
      description: description ?? this.description,
      referenceType: referenceType ?? this.referenceType,
      referenceId: referenceId ?? this.referenceId,
      counterpartyAccountId:
          counterpartyAccountId ?? this.counterpartyAccountId,
      counterpartyMovementId:
          counterpartyMovementId ?? this.counterpartyMovementId,
      metadata: metadata ?? this.metadata,
      organizationId: organizationId ?? this.organizationId,
      createdById: createdById ?? this.createdById,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}

/// Página paginada de movements (espejo del response del backend).
class BankAccountMovementPage extends Equatable {
  final List<BankAccountMovement> items;
  final int total;
  final int page;
  final int limit;

  const BankAccountMovementPage({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
  });

  @override
  List<Object?> get props => [items, total, page, limit];

  bool get hasNextPage => page * limit < total;
}
