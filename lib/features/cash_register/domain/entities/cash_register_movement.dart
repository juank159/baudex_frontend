// lib/features/cash_register/domain/entities/cash_register_movement.dart
import 'package:equatable/equatable.dart';

/// De dónde sale un movimiento del turno.
enum CashMovementKind { sale, creditPayment, expense }

/// Un movimiento de dinero del turno de caja, con su trazabilidad: a qué
/// hora, de qué factura o abono, por qué medio y, si fue por Bre-B, quién
/// pagó, desde qué banco y con qué referencia.
class CashRegisterMovement extends Equatable {
  final String id;
  final CashMovementKind kind;

  /// `cash`, `breb` o el código del método; coincide con el desglose.
  final String method;

  /// Nombre del medio tal como sale en el desglose ("Bre-B · Nequi").
  final String label;
  final double amount;
  final DateTime at;
  final String? invoiceId;
  final String? invoiceNumber;
  final String? customerName;
  final String? description;

  // Solo Bre-B
  final String? payerName;
  final String? bankLabel;
  final String? llave;
  final String? bankReference;

  const CashRegisterMovement({
    required this.id,
    required this.kind,
    required this.method,
    required this.label,
    required this.amount,
    required this.at,
    this.invoiceId,
    this.invoiceNumber,
    this.customerName,
    this.description,
    this.payerName,
    this.bankLabel,
    this.llave,
    this.bankReference,
  });

  bool get isBreb => method == 'breb';
  bool get isCash => method == 'cash';

  factory CashRegisterMovement.fromJson(Map<String, dynamic> json) {
    String? text(String key) {
      final value = json[key]?.toString().trim();
      return value == null || value.isEmpty ? null : value;
    }

    final kind = switch (json['kind']?.toString()) {
      'expense' => CashMovementKind.expense,
      'credit_payment' => CashMovementKind.creditPayment,
      _ => CashMovementKind.sale,
    };
    final rawAmount = json['amount'];
    return CashRegisterMovement(
      id: json['id']?.toString() ?? '',
      kind: kind,
      method: json['method']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      amount: rawAmount is num ? rawAmount.toDouble() : double.tryParse('$rawAmount') ?? 0,
      at: DateTime.tryParse(json['at']?.toString() ?? '')?.toLocal() ?? DateTime.fromMillisecondsSinceEpoch(0),
      invoiceId: text('invoiceId'),
      invoiceNumber: text('invoiceNumber'),
      customerName: text('customerName'),
      description: text('description'),
      payerName: text('payerName'),
      bankLabel: text('bankLabel'),
      llave: text('llave'),
      bankReference: text('bankReference'),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': switch (kind) {
          CashMovementKind.expense => 'expense',
          CashMovementKind.creditPayment => 'credit_payment',
          CashMovementKind.sale => 'sale',
        },
        'method': method,
        'label': label,
        'amount': amount,
        'at': at.toUtc().toIso8601String(),
        'invoiceId': invoiceId,
        'invoiceNumber': invoiceNumber,
        'customerName': customerName,
        'description': description,
        'payerName': payerName,
        'bankLabel': bankLabel,
        'llave': llave,
        'bankReference': bankReference,
      };

  @override
  List<Object?> get props => [id, kind, method, label, amount, at];
}

/// Los movimientos de un turno. [savedAt] viene cuando no hubo conexión y se
/// muestra lo último que se guardó en el equipo (puede faltar lo más reciente).
class CashRegisterMovements {
  final List<CashRegisterMovement> items;
  final DateTime? savedAt;

  const CashRegisterMovements(this.items, {this.savedAt});

  bool get fromDevice => savedAt != null;
}
